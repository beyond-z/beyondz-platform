BeyondzPlatform::Application.routes.draw do
  get "programs/college"
  root 'programs#college'

  # These are static routes for the college assignments for Phase 1.  In Phase 2, remove this and use
  # resourceful dynamic routes, database modles, views, etc to add new assignments.
  get "assignments/story-of-self", to: "assignments#story-of-self", as: :story_of_self_page
  get "assignments/passions-professions", to: "assignments#passions-professions", as: :passions_professions_page
  get "assignments/cover-letter", to: "assignments#cover-letter", as: :cover_letter_page
  get "assignments/resume", to: "assignments#resume", as: :resume_page
  get "assignments/networks", to: "assignments#networks", as: :networks_page
  get "assignments/spring-break", to: "assignments#spring-break", as: :spring_break_page
  get "assignments/asking-for-help", to: "assignments#asking-for-help", as: :asking_for_help_page
  get "assignments/interview-simulations", to: "assignments#interview-simulations", as: :interview_simulations_page
  get "assignments/work-ethic", to: "assignments#work-ethic", as: :work_ethic_page
  get "assignments/organization-self-mgmt", to: "assignments#organization-self-mgmt", as: :organization_self_mgmt_page
#  get "assignments/insertpath", to: "assignments#insertpath", as: :insertPath_page

  # Handle assignment submissions, such as GET <root>/assignments/submit/new  
  resources :assignments, only: [:index] do
    resources :submit, only: [:new, :create]
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
end
