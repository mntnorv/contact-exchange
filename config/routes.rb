Contacts::Application.routes.draw do
  root :to => 'home#index'

  # Account management
  devise_for :users, controllers: { omniauth_callbacks: "omniauth_callbacks" }
  get "account"               => "account#index",   :as => :account
  get "account/refresh_token" => "account#refresh", :as => :account_refresh_token

  # Users
  #get    "users/register"           => "users#register",    :as => :new_user_register
  #get    "users/:token"             => "users#show",        :as => :user
  #delete "users/:token"             => "users#destroy",     :as => :remove_user
  #post   "users/:token/add_contact" => "users#add_contact", :as => :add_contact
end