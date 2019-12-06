# Prevent CSRF attacks by raising an exception.
class ApplicationController < ActionController::Base

  # See: http://smartinez87.github.io/exception_notification/

  before_filter :prepare_exception_notifier
  private
  def prepare_exception_notifier
    request.env["exception_notifier.exception_data"] = {
      :current_user => current_user
    }
  end

  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  layout :default_layout
  before_action :save_external_referrer
  before_action :permit_lms_iframe
  before_filter :redirect_if_old

  private

  # We moved from beyondz.org to join.bebraven.org but I couldn't
  # get .htaccess redirects working on heroku, so I'm doing it in code.
  # Don't do it on dev though since you may have setup some funky domain stuff
  # to develop (e.g. you're using ngrok to expose your server to the internets)
  def redirect_if_old
    if Rails.env.production? && request.host != Rails.application.secrets.root_domain
      redirect_to "#{request.protocol}#{Rails.application.secrets.root_domain}#{request.fullpath}", :status => :moved_permanently
    end
  end

  def permit_lms_iframe
    secure = Rails.application.secrets.canvas_use_ssl ? 's' : ''
    domain = Rails.application.secrets.canvas_server
    port   = Rails.application.secrets.canvas_port
    if (secure && port != 443) || (!secure && port != 80)
      port = ":#{port}"
    else
      port = ''
    end

    response.headers['X-Frame-Options'] = "ALLOW-FROM http#{secure}://#{domain}#{port}"
    response.headers['Content-Security-Policy'] = "frame-ancestors 'self' http#{secure}://#{domain}#{port}"
  end

  def save_external_referrer
    if session[:referrer].nil?
      session[:referrer] = request.referrer
    end
  end

  # see: http://stackoverflow.com/questions/4982073/different-layout-for-sign-in-action-in-devise
  def default_layout
    if devise_controller?
      'public'
    else
      'application'
    end
  end

  # use controller specific JS whene requested
  # use: before_action :use_controller_js
  def use_controller_js
    @controller_js = params[:controller].split('/')[-1]
  end

  def require_student
    unless user_signed_in?
      flash[:error] = 'Please log in to see your assignments.'
      redirect_to new_user_session_path
    end
  end

  def require_coach
    unless user_signed_in? && current_user.coach?
      flash[:error] = 'Please log in to see your coaching dashboard.'
      redirect_to new_user_session_path
    end
  end

  # direct users to the proper path upon registration
  # We are now sending them all to a generic page, but I'm
  # keeping this method because we might change our mind back
  # and then we'd do to undo just to redo...
  def redirect_to_welcome_path(user)
    # FIXME: Hack for now. When spam problem is fixed, we want to wait for email activiation/confirmation
    if user.salesforce_campaign_id
      please_wait_path(new_user_id: user.id)
    else
      welcome_path(new_user_id: user.id)
    end
  end

  # code to redirect to the same place after login
  # from https://stackoverflow.com/questions/15944159/devise-redirect-back-to-the-original-location-after-sign-in-or-sign-up

    before_action :store_user_location!, if: :storable_location?
    # The callback which stores the current location must be added before you authenticate the user 
    # as `authenticate_user!` (or whatever your resource is) will halt the filter chain and redirect 
    # before the location can be stored.

    # Its important that the location is NOT stored if:
    # - The request method is not GET (non idempotent)
    # - The request is handled by a Devise controller such as Devise::SessionsController as that could cause an 
    #    infinite redirect loop.
    # - The request is an Ajax request as this can lead to very unexpected behaviour.
    def storable_location?
      request.get? && is_navigational_format? && !devise_controller? && !request.xhr? && request.path != new_user_path
    end

    def store_user_location!
      store_location_for(:user, request.fullpath)
    end
  # done

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
    ].sort

    @fields = [
      'Accounting',
      'Actuarial Science',
      'Advertising',
      'Aerospace',
      'African American Studies',
      'African Studies',
      'Agriculture',
      'American Indian Studies',
      'American Studies',
      'Anatomy',
      'Animation',
      'Anthropology',
      'Archaeology',
      'Architecture',
      'Art History',
      'Asian American Studies',
      'Asian Studies',
      'Astronomy',
      'Banking',
      'Beauty / Cosmetics',
      'Biology',
      'Biomedical Engineering',
      'Biotechnology',
      'Business',
      'Cartography',
      'Chemical',
      'Chemical Engineering',
      'Chemistry',
      'Child Development',
      'Civil Engineering',
      'Cognitive Science',
      'Communications',
      'Computer Engineering',
      'Computer Hardware',
      'Computer Hardware Engineering',
      'Computer Science',
      'Construction Trades',
      'Creative Writing',
      'Criminal Justice',
      'Criminology',
      'Culinary Arts',
      'Dance',
      'Diversity Studies',
      'Ecology',
      'Economics',
      'Education',
      'Electrical Engineering',
      'Electronics',
      'Employment / Human Resources',
      'Energy',
      'English / Literature',
      'Environmental Studies',
      'Equestrian Studies',
      'European Studies',
      'Fashion',
      'Film',
      'Financial Services',
      'Fine Arts',
      'Food & Beverage',
      'Food Science',
      'Foreign Language',
      'Gay and Lesbian Studies',
      'Gender Studies',
      'Genetics',
      'Geography',
      'Graphic Design',
      'Health',
      'History',
      'Hospitality',
      'Human Biology',
      'Human Resources',
      'Human Services',
      'Industrial Engineering',
      'Information Technology',
      'Insurance',
      'Interior Design',
      'Journalism',
      'Journalism / News / Media',
      'Landscape Architecture',
      'Latin American Studies',
      'Latinx Studies',
      'Law',
      'Law / Legal Studies',
      'Library Science',
      'Management / Strategic Consulting',
      'Manufacturing',
      'Marine Sciences',
      'Maritime Studies',
      'Marketing',
      'Math',
      'Mechanical Engineering',
      'Medical Devices & Supplies',
      'Medicine',
      'Military',
      'Music',
      'Neurosciences',
      'Nursing',
      'Nutrition',
      'Performing Arts',
      'Pharmaceutical',
      'Philosophy',
      'Physics',
      'Political Science',
      'Psychology',
      'Public Administration',
      'Public Health',
      'Public Relations',
      'Publishing',
      'Real Estate',
      'Religion',
      'Social Work',
      'Sociology',
      'Software Engineering',
      'Sports',
      'Sports and Fitness',
      'Statistics',
      'Technology',
      'Telecommunications',
      'Theater',
      'Theology',
      'Tourism',
      'Transportation / Travel',
      'Urban Planning',
      'Urban Studies',
      'Visual Arts',
      'Women\'s Studies',
      'Writing'
    ].sort

    @job_functions = [
      "Administrative Services",
      "Arts and Design",
      "Business Development",
      "Community & Social Services",
      "Engineering",
      "Entrepreneurship",
      "Graphic Design",
      "Human Resources",
      "Military & Protective Services",
      "Operations",
      "Product Management",
      "Program Management",
      "Project Management",
      "Purchasing",
      "Quality Assurance",
      "Recruiting",
      "Research",
      "Sales",
      "Writing"
    ].sort

    @how_heard = [
      'Web Search',
      'Friend',
      'Colleague',
      'Social Media',
      'Other',
      'Braven Outreach',
      'Volunteer Match',
      'Employer',
      'Returning Volunteer',
      'Listserv'
    ].sort
  end

end
