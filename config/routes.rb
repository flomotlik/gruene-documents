Rails.application.routes.draw do
  get '/documents/search', to: 'documents#search'
  resources :documents
  root 'documents#index'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
