class ChampionsController < ApplicationController
  layout 'public'

  before_filter :set_up_lists

  def index
  end

  before_filter :authenticate_user!, :only => [:connect]
  def connect
    # FIXME: prompt linked in access from user

    @results = []

    if params[:view_all]
      @results = Champion.all
    end

    if params[:studies_csv]
      studies = params[:studies_csv].split(',').map(&:strip).reject(&:empty?)
      studies.each do |s|
        Champion.where("studies @> ?","{#{s}}").each do |c|
          @results << c
        end
      end
    end

    if params[:industries_csv]
      industries = params[:industries_csv].split(',').map(&:strip).reject(&:empty?)
      industries.each do |s|
        Champion.where("industries @> ?","{#{s}}").each do |c|
          @results << c
        end
      end
    end

    @results = @results.sort.uniq
  end

  def request_contact
    # the champion ids are passed by the user checking their boxes
    champion_ids = params[:champion_ids]

    champion_ids.each do |cid|
      recipient = Champion.find(cid)

      ChampionContact.create(
        :user_id => current_user.id,
        :champion_id => cid
      )

      hit = recipient.industries.any? ? recipient.industries.first : recipient.studies.fist

      ChampionsMailer.connect_request(recipient, current_user, hit).deliver
    end
  end

  def fellow_survey
    @contact = ChampionContact.find(params[:id])
    @champion = Champion.find(@contact.champion_id)
  end

  def champion_survey
    @contact = ChampionContact.find(params[:id])
    @fellow = User.find(@contact.user_id)
  end

  def fellow_survey_save
    @contact = ChampionContact.find(params[:id])
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
    @contact.fellow_survey_answered_at = DateTime.now
    @contact.save
  end

  def champion_survey_save
    @contact = ChampionContact.find(params[:id])
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

    n = Champion.new(champion)
    if !n.valid? || n.errors.any?
      @champion = n
      if session[:linkedin_access_token]
        @linkedin_present = true
      end
      render 'new'
      return
    end

    n.access_token = session.delete(:linkedin_access_token)

    n.save

    n.create_on_salesforce
    ChampionsMailer.new_champion(n).deliver
  end

  def set_up_lists
    @industries = [
      'Accounting',
      'Advertising',
      'Aerospace',
      'Banking',
      'Beauty / Cosmetics',
      'Biotechnology ',
      'Business',
      'Chemical',
      'Communications',
      'Computer Engineering',
      'Computer Hardware ',
      'Education',
      'Electronics',
      'Employment / Human Resources',
      'Energy',
      'Fashion',
      'Film',
      'Financial Services',
      'Fine Arts',
      'Food & Beverage ',
      'Health',
      'Information Technology',
      'Insurance',
      'Journalism / News / Media',
      'Law',
      'Management / Strategic Consulting',
      'Manufacturing',
      'Medical Devices & Supplies',
      'Performing Arts ',
      'Pharmaceutical ',
      'Public Administration',
      'Public Relations',
      'Publishing',
      'Marketing ',
      'Real Estate ',
      'Sports ',
      'Technology ',
      'Telecommunications',
      'Tourism',
      'Transportation / Travel',
      'Writing'
    ]

    @fields = [
      'Accounting ',
      'African American Studies ',
      'African Studies ',
      'Agriculture ',
      'American Indian Studies ',
      'American Studies ',
      'Architecture ',
      'Asian American Studies ',
      'Asian Studies ',
      'Dance',
      'Visual Arts',
      'Theater',
      'Music',
      'English / Literature ',
      'Film',
      'Foreign Language ',
      'Graphic Design',
      'Philosophy ',
      'Religion ',
      'Business',
      'Marketing',
      'Actuarial Science',
      'Hospitality ',
      'Human Resources ',
      'Real Estate ',
      'Health',
      'Public Health ',
      'Medicine ',
      'Nursing ',
      'Gender Studies ',
      'Urban Studies ',
      'Latin American Studies ',
      'European Studies ',
      'Gay and Lesbian Studies ',
      'Latinx Studies ',
      'Women’s Studies ',
      'Education ',
      'Psychology ',
      'Child Development',
      'Computer Science ',
      'History ',
      'Biology ',
      'Cognitive Science ',
      'Human Biology ',
      'Diversity Studies ',
      'Marine Sciences ',
      'Maritime Studies ',
      'Math',
      'Nutrition ',
      'Sports and Fitness ',
      'Law / Legal Studies ',
      'Military ',
      'Public Administration ',
      'Social Work ',
      'Criminal Justice ',
      'Theology ',
      'Equestrian Studies ',
      'Food Science ',
      'Urban Planning',
      'Art History ',
      'Interior Design ',
      'Landscape Architecture ',
      'Chemistry ',
      'Physics ',
      'Chemical Engineering ',
      'Software Engineering ',
      'Industrial Engineering ',
      'Civil Engineering',
      'Electrical Engineering ',
      'Mechanical Engineering ',
      'Biomedical Engineering',
      'Computer Hardware Engineering',
      'Anatomy ',
      'Ecology ',
      'Genetics ',
      'Neurosciences',
      'Communications ',
      'Animation ',
      'Journalism ',
      'Information Technology  ',
      'Aerospace',
      'Geography',
      'Statistics ',
      'Environmental Studies ',
      'Astronomy ',
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
