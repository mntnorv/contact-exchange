Contacts::Application.routes.draw do
  root :to => 'home#index'

  # Account management
  devise_for :users, controllers: { omniauth_callbacks: "omniauth_callbacks" }#, :skip => [:registrations]
  #get    "users/cancel" => "devise/registrations#cancel", :as => :cancel_user_registration
  #post   "users"        => "devise/registrations#create", :as => :user_registration
  #get    "users/edit"   => "devise/registrations#edit"  , :as => :edit_user_registration
  #patch  "users"        => "devise/registrations#update"
  #put    "users"        => "devise/registrations#update"
  #delete "users"        => "devise/registrations#destroy"

  get "account"               => "account#index",   :as => :account
  get "account/refresh_token" => "account#refresh", :as => :account_refresh_token

  # User page
  get  "users/:long_token" => "user_page#index",       :as => :user_page
  post "users/:long_token" => "user_page#add_contact"
  #get    "users/register"           => "users#register",    :as => :new_user_register
  #delete "users/:token"             => "users#destroy",     :as => :remove_user
  #post   "users/:token/add_contact" => "users#add_contact", :as => :add_contact
end