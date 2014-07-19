Contacts::Application.routes.draw do
  root :to => 'home#index'

  # Account management
  devise_for :users, controllers: { omniauth_callbacks: 'omniauth_callbacks' },
    skip: 'registrations'

  devise_scope :user do
    patch '/users', to: 'registrations#update', as: :user_registration
    put   '/users', to: 'registrations#update', as: nil
  end

  get 'profile' => 'profile#index', :as => :profile

  # User page
  get  'u/:long_token' => 'contact#index', :as => :user_page
  post 'u/:long_token' => 'contact#add_contact'
end

# cancel_user_registration_path   GET   /users/cancel(.:format)   registrations#cancel
# user_registration_path  POST  /users(.:format)  registrations#create
# new_user_registration_path  GET   /users/sign_up(.:format)  registrations#new
# edit_user_registration_path   GET   /users/edit(.:format)   registrations#edit
#   PATCH   /users(.:format)  registrations#update
#   PUT   /users(.:format)  registrations#update
#   DELETE  /users(.:format)  registrations#destroy 
