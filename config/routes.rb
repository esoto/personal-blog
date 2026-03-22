Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # API
  namespace :api do
    namespace :v1 do
      get "stats", to: "stats#index"
      resources :posts, param: :slug, only: %i[index show create update destroy] do
        member do
          post :publish
        end
      end
      post "preview", to: "previews#create"
      resources :comments, only: %i[index destroy] do
        member do
          patch :approve
          patch :spam
        end
      end
    end
  end

  # Authentication
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  # Admin
  namespace :admin do
    root "dashboard#index"
    post "posts/preview", to: "posts#preview", as: :posts_preview
    resources :posts
    resources :tags, except: :show
    resources :comments, only: [ :index, :destroy ] do
      member do
        patch :approve
        patch :spam
      end
    end
  end

  # RSS Feed
  get "feed", to: "feeds#index", defaults: { format: :rss }

  # Sitemap
  get "sitemap.xml", to: "sitemaps#show", defaults: { format: :xml }

  # Public posts
  resources :posts, only: [ :index ], param: :slug
  get "posts/:slug", to: "posts#show", as: :post_show
  post "posts/:slug/comments", to: "comments#create", as: :post_comments

  # Public tags
  get "tags", to: "tags#index", as: :tags
  get "tags/:slug", to: "tags#show", as: :tag

  # Static pages
  get "about", to: "pages#about"

  # Defines the root path route ("/")
  root "pages#home"
end
