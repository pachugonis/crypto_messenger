Rails.application.routes.draw do
  # Authentication
  resource :session
  resources :passwords, param: :token
  resource :registration, only: [ :new, :create ]
  resource :profile, only: [ :show, :edit, :update ] do
    delete :destroy_avatar, on: :member
  end

  # Two-factor authentication
  resource :two_factor_authentication, only: [ :new, :create ], path: "2fa", controller: "two_factor_authentication"
  resource :two_factor_settings, only: [ :show ], path: "settings/2fa" do
    post :enable, on: :collection
    post :verify, on: :collection
    delete :disable, on: :collection
    post :regenerate_codes, on: :collection
  end

  # Main application
  resources :rooms do
    resources :messages, only: [ :create, :update, :destroy ]
    resources :participants, controller: "room_participants", only: [ :new, :create, :destroy, :update ] do
      collection do
        get :search_users
      end
    end
    member do
      post :leave
      post :join
      post :mark_read
      delete :destroy_image
    end
  end

  resources :folders do
    member do
      get :new_share_link
      post :generate_share_link
      delete :revoke_share_link
    end
    resources :attachments, only: [ :create, :destroy ] do
      member do
        post :generate_link
      end
    end
  end

  # Shared folder access (public)
  get "shared_folder/:token", to: "folders#shared", as: :shared_folder

  # Shared attachments (access by token)
  get "shared/:token", to: "attachments#shared", as: :shared_attachment

  # Search
  get "search", to: "search#index"

  # Admin panel
  namespace :admin do
    root to: "dashboard#index"
    resources :users, only: [ :index, :show, :update, :destroy ] do
      member do
        post :lock
        post :unlock
        post :make_admin
        post :remove_admin
      end
    end
    resources :rooms, only: [ :index, :show, :destroy ]
    get "statistics", to: "statistics#index"
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Root path
  root "rooms#index"
end
