BeyondzPlatform::Application.routes.draw do
  devise_for :users, controllers: { confirmations: 'confirmations', sessions: 'sessions', passwords: 'passwords' }

  root "home#index"
  get '/welcome', to: 'home#welcome'
  get '/activating', to: 'home#please_wait', as: :please_wait
  get '/apply', to: 'home#apply'
  get '/donate', to: 'home#donate'
  get '/volunteer', to: 'home#volunteer'
  get '/partner', to: 'home#partner'
  get '/supporter_info', to: 'home#supporter_info'
  get '/jobs', to: 'home#jobs'

  # These convenience routes are meant to be given to
  # people during in-person recruitment efforts

  get '/volunteer/signup', to: redirect('/signup/new?applicant_type=volunteer')
  get '/student/signup', to: redirect('/signup/new?applicant_type=undergrad_student')
  get '/employer/signup', to: redirect('/signup/new?applicant_type=employer')
  get '/partner/signup', to: redirect('/signup/new?applicant_type=partner')

  # and back to the application itself

  get '/salesforce/change_apply_now', to: 'salesforce#change_apply_now'
  get '/salesforce/record_converted_leads', to: 'salesforce#record_converted_leads'
  get '/salesforce/sync_to_lms', to: 'salesforce#sync_to_lms'

  resources :feedback
  resources :comments
  get '/signup', to: 'users#new' # This is not really a proper REST path, but we don't have a show operation so this is for convenience (e.g. talking to someong at an event: "hey just go to bz.org/signup to signup!")
  resources :users, only: [:new, :create], :path => :signup

  post '/users/reset', to: 'users#reset', as: 'user_reset'
  get '/users/clear_session_cookie', to: 'users#clear_session_cookie'
  get '/users/not_on_lms', to: 'users#not_on_lms'
  get '/users/confirm', to: 'users#confirm', as: 'user_confirm'
  post '/users/confirm_slot', to: 'users#confirm_part_2', as: 'user_confirm_part_2'
  post '/users/confirm', to: 'users#save_confirm', as: 'user_save_confirm'

  resources :enrollments, only: [:new, :create, :show, :update]

  post '/users/check_credentials', to: 'users#check_credentials'

  resources :assignments, only: [:index, :update, :show] do
    resources :tasks, only: [:update, :show]
  end

  namespace :coach do
    root "home#index"

    resources :assignments
    resources :students do
      resources :tasks
    end
  end

  namespace :admin do
    root "home#index"

    get '/users/csv_import', to: 'users#csv_import', as: 'csv_import'
    post '/users/csv_import', to: 'users#do_csv_import'

    get '/users/lead_owner_mapping', to: 'users#lead_owner_mapping', as: 'lead_owner_mapping'
    get '/users/import_lead_owner_mapping', to: 'users#import_lead_owner_mapping', as: 'import_lead_owner_mapping'
    post '/users/import_lead_owner_mapping', to: 'users#do_import_lead_owner_mapping'

    get '/users/user_status_csv_import', to: 'users#user_status_csv_import', as: 'user_status_csv_import'
    post '/users/user_status_csv_import', to: 'users#do_user_status_csv_import'

    get '/users/:id/find_by_salesforce_id', to: 'users#find_by_salesforce_id', as: 'user_find_by_salesforce_id'
    get '/users/:id/enroll_by_salesforce_id', to: 'users#enroll_by_salesforce_id', as: 'user_enroll_by_salesforce_id'

    get '/campaign_mapping', to: 'users#campaign_mapping', as: 'campaign_mapping'
    post '/campaign_mapping', to: 'users#do_campaign_mapping'

    get '/bulk_student_upload', to: 'users#bulk_student_upload', as: 'bulk_student_upload'
    post '/bulk_student_upload', to: 'users#do_bulk_student_upload'

    resources :lists

    resources :users do
      resources :students
    end

    resources :coaches, controller: 'users' do
      resources :students
    end

    resources :students, controller: 'users'

    resources :enrollments
  end

  get '/assignments/:action', controller: 'assignments' # For the hard-coded assignment details

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
end
