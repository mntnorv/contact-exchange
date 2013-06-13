Contacts::Application.routes.draw do
  root :to => 'home#index'

  # Users
  get    "users/:hash" => "users#show",     :as => :user
  put    "users/:hash" => "users#update",   :as => :update_user
  get    "register"    => "users#register", :as => :register
  delete "users/:hash" => "users#destroy",  :as => :remove_user
end