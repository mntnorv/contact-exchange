class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    user = User.from_omniauth(request.env['omniauth.auth'])
    user.add_ce_group
    sign_in_and_redirect user
  end
end
