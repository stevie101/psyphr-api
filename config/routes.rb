Rails.application.routes.draw do
  
  namespace 'api' do
    
    get 'test'

    resources :end_entities, only: [:create] do
      resource :certificate, controller: 'end_entities/certificates' do
        get 'fingerprint'
      end
    end

    resources :apps, controller: 'sec_apps' do
      member do
        get ':filename', to: 'sec_apps#crl'
      end
    end

  end
  
  root 'application#index'

end
