require 'digest/md5'
require 'json'

class User < ActiveRecord::Base
  attr_accessible :access_token, :email, :last_refresh, :refresh_token, :user_hash

  validates :access_token,  :presence => true
  validates :email,         :presence => true
  validates :user_hash,     :presence => true,
                            :length => { :is => 32 }
  validates :last_refresh,  :presence => true
  validates :refresh_token, :presence => true

  ##
  # Get user information from Google
  #
  # @param [Signet::OAuth2::Client] signet_client An authorized
  #   Signet client. Gets info from the authorized this user.
  def update_user_info!(signet_client)
    self.access_token = signet_client.access_token
    self.refresh_token = signet_client.refresh_token
    self.last_refresh = signet_client.issued_at

    response = signet_client.fetch_protected_resource(
      :uri => "https://www.googleapis.com/oauth2/v1/userinfo?alt=json"
    )

    user_data = JSON.parse response.body
    hash_data = "%{google_id};%{name};%{email}" % {
      :google_id => user_data['id'],
      :name => user_data['name'],
      :email => user_data['email']
    }

    self.email = user_data['email']
    self.user_hash = Digest::MD5.hexdigest(hash_data)
  end
end
