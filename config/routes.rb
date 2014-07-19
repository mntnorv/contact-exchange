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

  # Errors
  get '404' => 'error#error_404', as: :error_404
end
