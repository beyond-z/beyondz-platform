BeyondzPlatform::Application.routes.draw do
  root "home#index"

  get "/users/login", to: "users#login" # defines users_login_path for use in the form
  get '/users/:action', controller: 'users'
  post '/users/:action', controller: 'users'

  get '/coaches', to: 'coaches#index'
  get '/coaches/:action', controller: 'coaches'
  post '/coaches/:action', controller: 'coaches'
  patch '/coaches/:action', controller: 'coaches'

  resources :feedback


  resources :assignments, only: [:index, :update] do
    resources :tasks, only: [:index, :update]
  end


  namespace :admin do
    root "home#index"
    resources :users do
      resources :students
    end
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
