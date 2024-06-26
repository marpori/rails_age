Rails.application.routes.draw do
  namespace :flintstones do
    resources :characters
  end

  resources :characters
  resources :has_dogs
  namespace :people do
    resources :has_cats
  end

  namespace :animals do
    resources :cats
  end

  resources :dogs
  # route for people controller
  resources :people

  # not needed with the engine
  # mount RailsAge::Engine => "/rails_age"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Defines the root path route ("/")
  root 'people#index'
end
