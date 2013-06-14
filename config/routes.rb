Contacts::Application.routes.draw do
  root :to => 'home#index'

  # Users
  get    "register"                => "users#register",    :as => :register
  get    "users/:hash"             => "users#show",        :as => :user
  delete "users/:hash"             => "users#destroy",     :as => :remove_user
  post   "users/:hash/add_contact" => "users#add_contact", :as => :add_contact
end