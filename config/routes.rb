Rails.application.routes.draw do
  mount RailsIcons::Engine, at: "/rails_icons"
  mount ActionCable.server => "/cable"
  resource :session
  resources :passwords, param: :token

  namespace :bots do
    get "SKILL.md", to: "tools#skill", as: :skill
    post :authorize, controller: "authorizations"
    resources :authorizations, only: :show, param: :request_token do
      member do
        post :approve
        post :reject
        post :token
      end
    end
    resources :tools, only: %i[ index show ] do
      post :execute, on: :member
    end
    get :workspace, controller: "tools"
  end

  resources :workspaces do
    post :reset_bot_share_code, on: :member
    resources :api_tokens, only: %i[ create destroy ]
    resources :workspace_services, only: %i[ show create update destroy ]
    get :invocations, on: :member
  end
  resources :services, only: %i[ index new create show update destroy ] do
    get ":kind/new", action: "new", on: :collection, as: :new_kind_service
    post "test_connection", action: "test_connection", on: :collection
  end

  # OAuth browser dance. `start` bounces the user to the provider; `callback`
  # receives the authorization code. A single global callback keeps the
  # registered provider redirect_uri constant; the target service + client
  # travel in a signed `state`.
  get "oauth/start", to: "oauth#start", as: :oauth_start
  get "oauth/callback", to: "oauth#callback", as: :oauth_callback
  resources :oauth_client_credentials, only: %i[ index new create edit update destroy ]

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is alive.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "workspaces#index"
end
