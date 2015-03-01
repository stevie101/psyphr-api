Rails.application.routes.draw do
  
  get 'login', to: 'sessions#new', as: :login
  get 'join', to: 'users#new', as: :join
  get 'logout', to: 'sessions#destroy', as: :logout
  
  resources :sessions
  resources :users
  
  get '.well-known/est/:uuid/cacerts', to: 'api/est#cacerts'
  post '.well-known/est/:uuid/simpleenroll', to: 'api/est#simpleenroll'
  post '.well-known/est/:uuid/simplereenroll', to: 'api/est#simplereenroll'
  
  namespace 'api' do
    
    get 'test'

    resources :end_entities, only: [] do
      resource :certificate, controller: 'end_entities/certificates' do
        get 'fingerprint'
      end
    end

  end
  
  resource :admin, controller: 'admin'
  
  namespace 'admin' do
    resources :users
    resources :apps, controller: 'sec_apps' do
      get 'client_key_pem'
      get 'client_key_der'
      get 'client_cert_pem'
      get 'client_cert_der'
      get 'client_pkcs12_der'
      get 'ca_cert_pem'
      get 'ca_cert_der'
      post 'revoke_client_cert'
      post 'revoke_ca_cert'
      get 'download_crl'
      resources :end_entities
    end
    resources :end_entities do
      post :enrol
      get 'cert_pem'
      get 'cert_der'
      resources :certificates, controller: 'end_entities/certificates' do
        post 'revoke'
        post 'renew'
      end
    end
  
  end
  
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'web#index'

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
