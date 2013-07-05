Contacts::Application.routes.draw do
  root :to => 'home#index'

  devise_for :users, controllers: { omniauth_callbacks: "omniauth_callbacks" }

  # Users
  #get    "users/register"           => "users#register",    :as => :new_user_register
  #get    "users/:token"             => "users#show",        :as => :user
  #delete "users/:token"             => "users#destroy",     :as => :remove_user
  #post   "users/:token/add_contact" => "users#add_contact", :as => :add_contact
end