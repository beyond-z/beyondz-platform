BeyondzPlatform::Application.routes.draw do
  devise_for :users, controllers: { confirmations: 'confirmations', sessions: 'sessions', passwords: 'passwords' }

  root "home#index"

  # No specific analog on WP yet, just send them to the redirect -> home page.
  get '/jobs', to: 'home#index'
  get '/donate', to: 'home#index'

  # These are part of the signup flow and NOT moved to the blog, they should stay here.
  get '/welcome', to: 'home#welcome'
  get '/activating', to: 'home#please_wait', as: :please_wait
  get '/activating_status', to: 'home#please_wait_status', as: :please_wait_status

  # These convenience routes are meant to be given to
  # people during in-person recruitment efforts

  get '/coach/signup', to: redirect('/signup/new?applicant_type=leadership_coach')
  get '/student/signup', to: redirect('/signup/new?applicant_type=undergrad_student')
  get '/employer/signup', to: redirect('/signup/new?applicant_type=employer')
  get '/partner/signup', to: redirect('/signup/new?applicant_type=partner')
  # Old URL, here for backwards compatibility
  get '/volunteer/signup', to: redirect('/signup/new?applicant_type=leadership_coach')

  # and back to the application itself

  resources :resumes
  resources :referrals

  get '/connect', to: 'champions#connect', as: :champions_connect
  get '/connect_authenticated', to: 'champions#connect_authenticated', as: :champions_connect_authenticated
  get '/champions/openid_login_start', to: 'champions#openid_login_start'
  get '/champions/openid_login_complete', to: 'champions#openid_login_complete'
  post '/champions/email_processor', to: 'champions#email_processor'
  get '/champions/terms', to: 'champions#terms', as: :champions_terms
  get '/champions/linkedin_authorize', to: 'champions#linkedin_authorize', as: :linkedin_authorize
  get '/champions/linkedin_oauth_success', to: 'champions#linkedin_oauth_success', as: :linkedin_oauth_success
  post '/champions/request_contact', to: 'champions#request_contact', as: :request_champion_contact
  get '/champions/search_stats', to: 'champions#search_stats', as: :search_stats
  get '/champions/contact/:id', to: 'champions#contact', as: :champions_contact
  delete '/champions/contact/:id', to: 'champions#delete_contact', as: :delete_champion_contact
  get '/champions/fellow_survey/:id', to: 'champions#fellow_survey', as: :champion_fellow_survey
  get '/champions/champion_survey/:id', to: 'champions#champion_survey', as: :champion_champion_survey
  post '/champions/fellow_survey/:id', to: 'champions#fellow_survey_save'
  post '/champions/champion_survey/:id', to: 'champions#champion_survey_save'
  patch '/champions/fellow_survey/:id', to: 'champions#fellow_survey_save', as: :champion_fellow_survey_save
  patch '/champions/champion_survey/:id', to: 'champions#champion_survey_save', as: :champion_champion_survey_save
  resources :champions

  get '/salesforce/change_apply_now', to: 'salesforce#change_apply_now'
  get '/salesforce/disable_osqa_notification_emails', to: 'salesforce#disable_osqa_notification_emails'
  get '/salesforce/sync_report_to_google_spreadsheet', to: 'salesforce#sync_report_to_google_spreadsheet'
  get '/salesforce/record_converted_leads', to: 'salesforce#record_converted_leads'
  get '/salesforce/sync_to_lms', to: 'salesforce#sync_to_lms'
  get '/salesforce/change_campaigns', to: 'salesforce#change_campaigns'
  post '/salesforce/change_campaigns', to: 'salesforce#change_campaigns'

  # Add hook for calendly to call when Invitees either signup for or cancel their signup for an event
  post '/calendly/invitee_action', to:'calendly#invitee_action'

  resources :feedback
  resources :comments
  get '/signup', to: 'users#new' # This is not really a proper REST path, but we don't have a show operation so this is for convenience (e.g. talking to someong at an event: "hey just go to bz.org/signup to signup!")
  resources :users, only: [:new, :create], :path => :signup

  post '/users/reset', to: 'users#reset', as: 'user_reset'
  post '/users/phone', to: 'users#phone', as: 'user_phone'
  get '/users/clear_session_cookie', to: 'users#clear_session_cookie'
  get '/users/not_on_lms', to: 'users#not_on_lms'
  get '/users/sso_discovery', to: 'users#sso_discovery'
  get '/users/confirm', to: 'users#confirm', as: 'user_confirm'
  post '/users/confirm_slot', to: 'users#confirm_part_2', as: 'user_confirm_part_2'
  post '/users/confirm', to: 'users#save_confirm', as: 'user_save_confirm'
  get '/users/student_confirm', to: 'users#student_confirm', as: 'user_student_confirm'
  post '/users/student_confirm', to: 'users#save_student_confirm', as: 'user_save_student_confirm'

  resources :enrollments, only: [:new, :create, :show, :update]

  post '/users/check_credentials', to: 'users#check_credentials'

  resources :assignments, only: [:index, :update, :show] do
    resources :tasks, only: [:update, :show]
  end

  namespace :admin do
    root "home#index"

    get '/assignments/get_due_dates', to: 'assignments#get_due_dates', as: 'get_due_dates'
    post '/assignments/get_due_dates', to: 'assignments#download_due_dates', defaults: { format: 'csv' }

    get '/assignments/set_due_dates', to: 'assignments#set_due_dates', as: 'set_due_dates'
    post '/assignments/set_due_dates', to: 'assignments#do_set_due_dates'

    get '/events/get_events', to: 'events#get_events', as: 'get_events'
    post '/events/get_events', to: 'events#download_events'

    get '/events/set_events', to: 'events#set_events', as: 'set_events'
    post '/events/set_events', to: 'events#do_set_events'



    get '/users/canvas_page_views', to: 'users#canvas_page_views', as: 'canvas_page_views'
    get '/users/get_canvas_page_views', to: 'users#get_canvas_page_views', as: 'get_canvas_page_views'

    get '/users/csv_import', to: 'users#csv_import', as: 'csv_import'
    post '/users/csv_import', to: 'users#do_csv_import'

    post '/users/:id/impersonate', to: 'users#impersonate', as: 'impersonate'

    get '/users/lead_owner_mapping', to: 'users#lead_owner_mapping', as: 'lead_owner_mapping'
    get '/users/import_lead_owner_mapping', to: 'users#import_lead_owner_mapping', as: 'import_lead_owner_mapping'
    post '/users/import_lead_owner_mapping', to: 'users#do_import_lead_owner_mapping'

    get '/users/request_spreadsheet', to: 'users#request_spreadsheet', as: 'request_spreadsheet'
    post '/users/request_spreadsheet', to: 'users#do_request_spreadsheet'

    get '/users/user_status_csv_import', to: 'users#user_status_csv_import', as: 'user_status_csv_import'
    post '/users/user_status_csv_import', to: 'users#do_user_status_csv_import'

    get '/users/:id/find_by_salesforce_id', to: 'users#find_by_salesforce_id', as: 'user_find_by_salesforce_id'
    get '/users/:id/enroll_by_salesforce_id', to: 'users#enroll_by_salesforce_id', as: 'user_enroll_by_salesforce_id'

    get '/campaign_mapping', to: 'users#campaign_mapping', as: 'campaign_mapping'
    post '/campaign_mapping', to: 'users#do_campaign_mapping'

    get '/bulk_student_upload', to: 'users#bulk_student_upload', as: 'bulk_student_upload'
    post '/bulk_student_upload', to: 'users#do_bulk_student_upload'

    resources :lists

    resources :resumes

    resources :users

    # resources :champions
    get '/champions/contacts.csv', to: 'champions#download_contacts', as: 'champion_surveys', defaults: { format: 'csv' }
    get '/champions/report', to: 'champions#report', as: 'champion_report'

    get '/champions/search_stats', to: 'champions#search_stats', as: 'champions_search_stats'
    get '/champions/synonyms', to: 'champions#synonyms', as: 'champions_synonyms'

    resources :enrollments

    resources :task_definitions
    resources :assignment_definitions
  end

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end


  # OpenID stuff
  get '/openid/server/xrds', :controller => 'openid', :action => 'idp_xrds'
  get '/openid/user/:username', :controller => 'openid', :action => 'user_page'
  get '/openid/user/:username/xrds', :controller => 'openid', :action => 'user_xrds'
  post '/openid/server/xrds', :controller => 'openid', :action => 'idp_xrds'
  post '/openid/user/:username', :controller => 'openid', :action => 'user_page'
  post '/openid/user/:username/xrds', :controller => 'openid', :action => 'user_xrds'

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  get '/openid/service.wsdl', :controller => 'openid', :action => 'wsdl'

  # Install the default route as the lowest priority.
  get '/openid/:action', :controller => 'openid'
  post '/openid/:action', :controller => 'openid'



end
