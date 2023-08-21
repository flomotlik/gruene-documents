Rails.application.routes.draw do
  devise_for :users
  get '/search', to: 'documents#search'
  resources :documents
  root 'documents#search'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
#   get "up" => "rails/health#show", as: :rails_health_check
end
