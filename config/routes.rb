Rails.application.routes.draw do
  # Authentication
  resource :session
  resources :passwords, param: :token
  resource :registration, only: [ :new, :create ]

  # Main application
  resources :rooms do
    resources :messages, only: [ :create, :update, :destroy ]
    resources :participants, controller: "room_participants", only: [ :create, :destroy, :update ]
    member do
      post :leave
      post :mark_read
    end
  end

  resources :folders do
    resources :attachments, only: [ :create, :destroy ] do
      member do
        post :generate_link
      end
    end
  end

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
