Contacts::Application.routes.draw do
  root :to => 'home#index'

  # Users
  get    "register"                 => "users#register",    :as => :register
  get    "users/:token"             => "users#show",        :as => :user
  delete "users/:token"             => "users#destroy",     :as => :remove_user
  post   "users/:token/add_contact" => "users#add_contact", :as => :add_contact
end