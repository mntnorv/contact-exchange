require 'oauth2'

class AccountController < ApplicationController
  before_filter :authenticate_user!

  # GET account
  def index
  end

  def refresh
    client = OAuth2::Client.new(
      Yetting.google_client_id,
      Yetting.google_client_secret,
      {
        :authorize_url => Yetting.google_auth_uri,
        :token_url => Yetting.google_token_uri
      }
    )

    access_token = OAuth2::AccessToken.new(
      client,
      current_user.access_token,
      {
        :refresh_token => current_user.refresh_token,
        :expires_at => current_user.access_token_expires_at
      }
    )

    access_token = access_token.refresh!
    current_user.access_token = access_token.token
    current_user.save!

    redirect_to account_url
  end
end