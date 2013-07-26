Contacts::Application.routes.draw do
  root :to => 'home#index'

  # Account management
  devise_for :users, controllers: { omniauth_callbacks: "omniauth_callbacks" }
  get "account"               => "account#index",   :as => :account
  get "account/refresh_token" => "account#refresh", :as => :account_refresh_token

  # User page
  get  "u/:long_token" => "user_page#index",       :as => :user_page
  post "u/:long_token" => "user_page#add_contact"
end