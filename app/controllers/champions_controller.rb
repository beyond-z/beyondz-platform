require 'uuidtools'

require 'openid'
require 'openid/store/filesystem'

class ChampionsController < ApplicationController
  layout 'public'

  before_filter :set_up_lists

  skip_before_filter :verify_authenticity_token, :only => [:email_processor]
  http_basic_authenticate_with name: "cloudmail", password: Rails.application.secrets.cloudmailin_password, :only => :email_processor
  def email_processor
    # The goal in here: archive the email for future reference
    # see if it is coming from the fellow or the champion
    # if the fellow's first time, start the connection clock and record that they did reach out
    # if the champion's first time, record that they did answer
    #
    # to tell who it is, the To address will include the interaction id, a directional indicator, and a security hash
    # so like c123-ab3af56e@champions.bebraven.org means "to champion, interaction #123, hash ab3af56e"
    #
    # Once we process and archive, we need to forward to the actual recipient and add/fix the
    # Reply-To header, the From header, and maybe the subject.
    #
    # From will say "Fellow's Name via Braven Champions <fxxx-dddd@champions.bebraven.org>"


    to = params[:envelope][:to]

    extracted = to.match(/([cf])([0-9]+)-([0-9a-zA-Z]+)@champions.bebraven.org/)

    to_party = extracted[1] # c or f
    interaction_id = extracted[2]
    security_hash = extracted[3]

    cc = ChampionContact.find(interaction_id)

    if security_hash != cc.security_hash
      render text: "Bad security code", status: 404
      return
    end

    # log it
    ccle = ChampionContactLoggedEmail.create(
      :champion_contact_id => cc.id,
      :to => to_party,
      :from => params[:envelope][:from],
      :subject => params[:headers][:Subject],
      :plain => params[:plain],
      :html => params[:html]
    )

    if params[:attachments]
      params[:attachments].each do |k, attachment|
        ChampionContactLoggedEmailAttachment.create(
          :champion_contact_logged_email => ccle,
          :file => attachment
        )
      end
    end


    # and forward it.
    ChampionsForwarderMailer.forward_message(to_party, cc, params[:headers][:Subject], params[:plain], params[:html], params[:attachments]).deliver


    render text: "OK"
  end

  def index
  end

  def openid_consumer
    if @consumer.nil?
      dir = Pathname.new(Rails.root).join('db').join('cstore')
      store = OpenID::Store::Filesystem.new(dir)
      @consumer = OpenID::Consumer.new(session, store)
    end
    return @consumer
  end

  def openid_login_start
    url = params[:url]
    if url.nil?
      redirect_to champion_connect_authenticated_path
    end

    oidreq = openid_consumer.begin(url)
    return_to = url_for :action => 'openid_login_complete', :only_path => false
    realm = url_for :action => 'index', :id => nil, :only_path => false
    
    if oidreq.send_redirect?(realm, return_to, params[:immediate])
      redirect_to oidreq.redirect_url(realm, return_to, params[:immediate])
    else
      render :text => oidreq.html_markup(realm, return_to, params[:immediate], {'id' => 'openid_form'})
    end
  end

  def openid_login_complete
    current_url = url_for(:action => 'openid_login_complete', :only_path => false)
    parameters = params.reject{|k,v|request.path_parameters[k]}
    parameters.reject!{|k,v|%w{action controller}.include? k.to_s}
    response = openid_consumer.complete(parameters, current_url)
    if response.status == OpenID::Consumer::SUCCESS
      user_url = params["openid.identity"]

      canvas_user_id = user_url[user_url.rindex('/') + 1 .. -1]
      user = User.where(:canvas_user_id => canvas_user_id)
      if user.any?
        sign_in(user.first)
        redirect_to :action => 'connect'
        return
      end
      # should never happen... if we got here, it means they had a Canvas OpenID URL,
      # which means the user is there... and thus should be here too due to sync to lms originating here!
      logger.debug user_id
      render text: "Your user wasn't found on the Braven server. Please contact support@bebraven.org and tell them this happened and what time it is when you saw this."
    else
      # open id failed should also never happen because the URL is given to us by Canvas, which
      # we also control!

      # flash[:message] = "Please log in using your Braven email and password you set up in the application process."
      redirect_to :action => 'connect_authenticated'
      # render :text => "FAILED #{response.inspect}"
    end
  end

  before_filter :authenticate_user!, :only => [:connect_authenticated, :request_contact, :contact, :fellow_survey, :fellow_survey_save]

  def connect_authenticated
    # the before filter forces them to log in, then we can go back to the other thing.
    redirect_to champions_connect_path
  end

  def connect
    # FIXME: prompt linked in access from user

    if !user_signed_in?
      # If the user isn't logged in, we want to try OpenID off Canvas via
      # a client side script
      render 'openid_auth'
      return
    end

    @active_requests = ChampionContact.active(current_user.id)
    @max_allowed = 2 - @active_requests.count
    if @max_allowed < 0
      @max_allowed = 0
    end

    @results = []
    @search_attempted = false

    if params[:view_all]
      @results = Champion.all
      @search_attempted = true
    end

    if params[:interests_csv]
      @search_attempted = true
      search_terms = params[:interests_csv].split(',').map(&:strip).reject(&:empty?)
      search_terms.each do |s|
        record_stat_hit(s)
        query = Champion.where("
          array_to_string(studies, ',') ILIKE ?
          OR
          array_to_string(industries, ',') ILIKE ?",
          "%#{s}%", # for studies
          "%#{s}%"  # for industries
        ).where("willing_to_be_contacted = true")
        if Rails.application.secrets.smtp_override_recipient.blank?
          query = query.where("email NOT LIKE '%@bebraven.org'")
        end
        query.each do |c|
          @results << c
        end
      end
    end

    @results = @results.sort.uniq

    results_filtered = []

    # soooo this is O(n*m) but I am banking on the number of ChampionContacts being
    # somewhat small since we limit the amount of interactions any user is allowed to have
    # and I am expecting the query to be cached.
    @results.each do |result|
      found = false
      ChampionContact.where(:user_id => current_user.id).each do |ar|
        if result.id == ar.champion_id
          found = true
          break
        end
      end

      if !found
        results_filtered << result
      end
    end

    @results = results_filtered
  end

  def terms
  end

  def record_stat_hit(word)
    word = word.downcase
    res = ChampionStats.where(:search_term => word)
    s = nil
    if res.empty?
      s = ChampionStats.new
      s.search_term = word
      s.search_count = 0
    else
      s = res.first
    end

    s.search_count += 1
    s.save
  end

  # I don't mind this being public cuz it is harmless and maybe even
  # useful later for sorting auto-complete lists. but i also don't advertise it.
  def search_stats
    @stats = ChampionStats.order(search_count: :desc)
  end

  def contact
    @other_active_requests = ChampionContact.active(current_user.id).where("id != ?", params[:id])
    cc = ChampionContact.find(params[:id])
    raise "wrong user" if cc.user_id != current_user.id

    @recipient = Champion.find(cc.champion_id)
    @hit = @recipient.industries.any? ? @recipient.industries.first : @recipient.studies.fist
    @cc = cc

    if params[:others]
      @others = params[:others]
    else
      @others = []
    end
  end

  def request_contact
    # the champion ids are passed by the user checking their boxes
    champion_ids = params[:champion_ids]

    ccs = []

    champion_ids.each do |cid|
      if ChampionContact.active(current_user.id).where(:champion_id => cid).any?
        ccs << ChampionContact.active(current_user.id).where(:champion_id => cid).first
        next
      end

      ccs << ChampionContact.create(
        :user_id => current_user.id,
        :champion_id => cid,
        :nonce => UUIDTools::UUID.random_create.to_s
      )
    end

    redirect_to champions_contact_path(ccs.first.id, :others => ccs[1 .. -1])
  end

  def fellow_survey
    @contact = ChampionContact.find(params[:id])
    return fellow_permission_denied if current_user.id != 1 && current_user.id != @contact.user_id
    @champion = Champion.find(@contact.champion_id)
  end

  def champion_survey
    @contact = ChampionContact.find(params[:id])
    return champion_permission_denied if !@contact.nonce.nil? && @contact.nonce != params[:nonce]
    @fellow = User.find(@contact.user_id)
  end

  def fellow_survey_save
    @contact = ChampionContact.find(params[:id])
    return fellow_permission_denied if current_user.id != 1 && current_user.id != @contact.user_id
    @contact.update_attributes(params[:champion_contact].permit(
      :champion_replied,
      :fellow_get_to_talk_to_champion,
      :why_not_talk_to_champion,
      :would_fellow_recommend_champion,
      :what_did_champion_do_well,
      :what_could_champion_improve,
      :reminder_requested,
      :inappropriate_champion_interaction,
      :fellow_comments
    ))
    if params[:champion_contact][:champion_replied] == 'true'
      @contact.reminder_requested = false
    end
    @contact.fellow_survey_answered_at = DateTime.now
    @contact.save

    if params[:champion_contact][:reminder_requested] == "true"
      @reminder_requested = true
      @reminder_email = Champion.find(@contact.champion_id).email
    end
  end

  def champion_survey_save
    @contact = ChampionContact.find(params[:id])
    return champion_permission_denied if !@contact.nonce.nil? && @contact.nonce != params[:nonce]
    @contact.update_attributes(params[:champion_contact].permit(
      :inappropriate_fellow_interaction,
      :champion_get_to_talk_to_fellow,
      :why_not_talk_to_fellow,
      :how_champion_felt_conversaion_went,
      :what_did_fellow_do_well,
      :what_could_fellow_improve,
      :champion_comments
    ))
    @contact.champion_survey_answered_at = DateTime.now
    @contact.save
  end

  def fellow_permission_denied
    render 'fellow_permission_denied', :status => :forbidden
  end

  def champion_permission_denied
    render 'champion_permission_denied', :status => :forbidden
  end

  def new
    @champion = Champion.new
  end

  def linkedin_authorize
    linkedin_connection = LinkedIn.new
    nonce = session[:oauth_linked_nonce] = SecureRandom.hex
    redirect_to linkedin_connection.authorize_url(linkedin_oauth_success_url, nonce)
  end

  def linkedin_oauth_success
    linkedin_connection = LinkedIn.new
    nonce = session.delete(:oauth_linked_nonce)
    raise Exception.new 'Wrong nonce' unless nonce == params[:state]

    if params[:error]
      # Note: if user cancels, then params[:error] == 'user_cancelled_authorize'
      flash[:error] = 'You declined LinkedIn, please use your email address to sign up.'
      Rails.logger.error("LinkedIn authorization failed. error = #{params[:error]}, error_description = #{params[:error_description]}")
      redirect_to new_champion_url(:showform => true)
      return
    end

    access_token = linkedin_connection.exchange_code_for_token(params[:code], linkedin_oauth_success_url)

    # Note: the service_user_id, service_user_name, and service_user_url are LinkedIn's data that we get
    # by calling into their API.  E.g. service_user_url maybe something like: https://www.linkedin.com/in/somelinkedinusername
    if access_token
      li_user = linkedin_connection.get_service_user_info(access_token)

      @champion = Champion.new
      @champion.first_name = li_user['first_name']
      @champion.last_name = li_user['last_name']
      @champion.email = li_user['email_address']
      @champion.company = li_user['company']
      @champion.job_title = li_user['job_title']
      @champion.linkedin_url = li_user['user_url']
      @champion.studies = li_user['majors']
      @champion.industries = li_user['industries']

      session[:linkedin_access_token] = access_token # keeping it on the server, don't even want to give this to the user
      # we might be able to pull in even more
      @linkedin_present = true
      render 'new'
    else
      Rails.logger.error('Error registering LinkedIn service for Champion. The access_token couldn\'t be retrieved using the code sent from LinkedIn')
      raise Exception.new 'Failed getting access token for LinkedIn'
    end
  end

  def create
    champion = params[:champion].permit(
      :first_name,
      :last_name,
      :email,
      :phone,
      :company,
      :job_title,
      :linkedin_url,
      :region,
      :braven_fellow,
      :braven_lc,
      :willing_to_be_contacted
    )

    # if JS is there, we'll get the csv, otherwise, it falls back to checkboxes
    if params[:industries_csv] && !params[:industries_csv].empty?
      champion[:industries] = params[:industries_csv].split(',').map(&:strip).reject(&:empty?)
    else
      champion[:industries] = params[:champion][:industries].reject(&:empty?)
    end

    if params[:studies_csv] && !params[:studies_csv].empty?
      champion[:studies] = params[:studies_csv].split(',').map(&:strip).reject(&:empty?)
    else
      champion[:studies] = params[:champion][:studies].reject(&:empty?)
    end

    was_new = false
    n = nil
    # duplicate check, if email exists, just update existing row
    existing = Champion.where(:email => champion[:email])
    if existing.any?
      n = existing.first
      n.update_attributes(champion)
    else
      n = Champion.new(champion)
      was_new = true
    end
    if !n.valid? || n.errors.any?
      @champion = n
      if session[:linkedin_access_token]
        @linkedin_present = true
      end
      render 'new'
      return
    end

    if session[:linkedin_access_token]
      n.access_token = session.delete(:linkedin_access_token)
    end

    # defensively limit string lengths before saving to ensure
    # they don't blow the column limit
    n.first_name = n.first_name[0 ... 240]
    n.last_name = n.last_name[0 ... 240]
    n.email = n.email[0 ... 240]
    n.phone = n.phone[0 ... 240]
    n.company = n.company[0 ... 240]
    n.job_title = n.job_title[0 ... 240]
    n.linkedin_url = n.linkedin_url[0 ... 240]
    n.region = n.region[0 ... 240]

    n.save

    n.create_on_salesforce

    if was_new
      ChampionsMailer.new_champion(n).deliver
    end
  end

  def set_up_lists
    @industries = [
      'Accounting',
      'Advertising',
      'Aerospace',
      'Banking',
      'Beauty / Cosmetics',
      'Biotechnology',
      'Business',
      'Chemical',
      'Communications',
      'Computer Engineering',
      'Computer Hardware',
      'Education',
      'Electronics',
      'Employment / Human Resources',
      'Energy',
      'Fashion',
      'Film',
      'Financial Services',
      'Fine Arts',
      'Food & Beverage',
      'Health',
      'Information Technology',
      'Insurance',
      'Journalism / News / Media',
      'Law',
      'Management / Strategic Consulting',
      'Manufacturing',
      'Medical Devices & Supplies',
      'Performing Arts',
      'Pharmaceutical',
      'Public Administration',
      'Public Relations',
      'Publishing',
      'Marketing',
      'Real Estate',
      'Sports',
      'Technology',
      'Telecommunications',
      'Tourism',
      'Transportation / Travel',
      'Writing'
    ]

    @fields = [
      'Accounting',
      'African American Studies',
      'African Studies',
      'Agriculture',
      'American Indian Studies',
      'American Studies',
      'Architecture',
      'Asian American Studies',
      'Asian Studies',
      'Dance',
      'Visual Arts',
      'Theater',
      'Music',
      'English / Literature',
      'Film',
      'Foreign Language',
      'Graphic Design',
      'Philosophy',
      'Religion',
      'Business',
      'Marketing',
      'Actuarial Science',
      'Hospitality',
      'Human Resources',
      'Real Estate',
      'Health',
      'Public Health',
      'Medicine',
      'Nursing',
      'Gender Studies',
      'Urban Studies',
      'Latin American Studies',
      'European Studies',
      'Gay and Lesbian Studies',
      'Latinx Studies',
      'Women’s Studies',
      'Education',
      'Psychology',
      'Child Development',
      'Computer Science',
      'History',
      'Biology',
      'Cognitive Science',
      'Human Biology',
      'Diversity Studies',
      'Marine Sciences',
      'Maritime Studies',
      'Math',
      'Nutrition',
      'Sports and Fitness',
      'Law / Legal Studies',
      'Military',
      'Public Administration',
      'Social Work',
      'Criminal Justice',
      'Theology',
      'Equestrian Studies',
      'Food Science',
      'Urban Planning',
      'Art History',
      'Interior Design',
      'Landscape Architecture',
      'Chemistry',
      'Physics',
      'Chemical Engineering',
      'Software Engineering',
      'Industrial Engineering',
      'Civil Engineering',
      'Electrical Engineering',
      'Mechanical Engineering',
      'Biomedical Engineering',
      'Computer Hardware Engineering',
      'Anatomy',
      'Ecology',
      'Genetics',
      'Neurosciences',
      'Communications',
      'Animation',
      'Journalism',
      'Information Technology',
      'Aerospace',
      'Geography',
      'Statistics',
      'Environmental Studies',
      'Astronomy',
      'Public Relations',
      'Library Science',
      'Anthropology',
      'Economics',
      'Criminology',
      'Archaeology',
      'Cartography',
      'Political Science',
      'Sociology',
      'Construction Trades',
      'Culinary Arts',
      'Creative Writing'
    ]
  end
end

require 'nokogiri'

class LinkedIn
  def config
    a = {}
    a['api_key'] = ENV['LINKEDIN_API_KEY']
    a['secret_key'] = ENV['LINKEDIN_API_SECRET']
    a
  end

  def get_request(path, access_token)
    http = Net::HTTP.new('api.linkedin.com', 443)
    http.use_ssl = true
    # http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(path)
    request['Authorization'] = "Bearer #{access_token}"
    response = http.request(request)

    response
  end

  def get_service_user_info(access_token)
    body = get_request('/v1/people/~:(id,first-name,last-name,public-profile-url,picture-url,email-address,three-past-positions,three-current-positions,industry,educations)?format=json', access_token).body
    data = JSON.parse(body)

    user = {}

    user['user_id'] = data['id']
    user['first_name'] = data['firstName']
    user['last_name'] = data['lastName']
    user['email_address'] = data['emailAddress']
    user['user_url'] = data['publicProfileUrl']
    user['majors'] = get_majors(data['educations'])
    user['industries'] = get_industries(data['threeCurrentPositions'], data['threePastPositions'])
    user['company'] = get_current_employer(data['threeCurrentPositions'])
    user['job_title'] = get_job_title(data['threeCurrentPositions'])

    user
  end

  def get_current_employer(node)
    current_employer_node = node['values'].find { |job| job['isCurrent'] == true } unless node['_total'] == 0
    current_employer_company_node = current_employer_node['company'] unless current_employer_node.nil?
    current_employer = current_employer_company_node['name'] unless current_employer_company_node.nil?
    current_employer
  end

  def get_job_title(node)
    current_employer_node = node['values'].find { |job| job['isCurrent'] == true } unless node['_total'] == 0
    job_title = current_employer_node['title'] unless current_employer_node.nil?
    job_title
  end

  def get_majors(educations_node)
    majors = []
    return majors if educations_node['_total'] == 0
    educations_node['values'].each do |n|
      majors.push(n['fieldOfStudy']) unless majors.include?(n['fieldOfStudy'])
    end
    majors
  end

  def get_industries(pn, past)
    industries = []
    if pn['_total'] != 0
      pn['values'].each do |n|
        company = n['company']
        next if company.nil?
        industries.push(company['industry']) unless industries.include?(company['industry'])
      end
    end
    if past['_total'] != 0
      past['values'].each do |n|
        company = n['company']
        next if company.nil?
        industries.push(company['industry']) unless industries.include?(company['industry'])
      end
    end

    industries
  end





  def authorize_url(return_to, nonce)
    "https://www.linkedin.com/oauth/v2/authorization?response_type=code&scope=r_emailaddress%20r_fullprofile&client_id=#{config['api_key']}&state=#{nonce}&redirect_uri=#{CGI.escape(return_to)}"
  end

  def exchange_code_for_token(code, redirect_uri)
    http = Net::HTTP.new('www.linkedin.com', 443)
    http.use_ssl = true
    # http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Post.new('/oauth/v2/accessToken')
    request.set_form_data(
      'grant_type' => 'authorization_code',
      'code' => code,
      'redirect_uri' => redirect_uri,
      'client_id' => config['api_key'],
      'client_secret' => config['secret_key']
    )
    response = http.request(request)

    info = JSON.parse response.body

    info['access_token']
  end
end
