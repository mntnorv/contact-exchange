require 'digest/md5'
require 'json'

class User < ActiveRecord::Base

  NEW_CONTACT_FORMAT = "<atom:entry xmlns:atom='http://www.w3.org/2005/Atom' xmlns:gContact='http://schemas.google.com/contact/2008' xmlns:gd='http://schemas.google.com/g/2005'><atom:category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/contact/2008#contact'/><gd:name><gd:givenName>%{first_name}</gd:givenName><gd:familyName>%{last_name}</gd:familyName></gd:name><gd:phoneNumber rel='http://schemas.google.com/g/2005#mobile' primary='true'>%{phone}</gd:phoneNumber><gContact:groupMembershipInfo deleted='false' href='http://www.google.com/m8/feeds/groups/%{user_email}/base/6'/></atom:entry>"

  # ActiveRecord fields
  attr_accessible :access_token, :email, :last_refresh, :name, :refresh_token, :user_hash
  
  # The user's OAuth client
  attr_accessor :oauth_client

  # ActiveRecord data validations
  validates :access_token,  :presence => true
  validates :email,         :presence => true
  validates :user_hash,     :presence => true,
                            :length => { :is => 32 }
  validates :last_refresh,  :presence => true
  validates :refresh_token, :presence => true

  # Initialize the OAuth client after ActiveRecord initialization
  after_initialize :init_oauth_client

  #
  # Getters
  #

  def access_token
    @oauth_client.access_token
  end

  def refresh_token
    @oauth_client.refresh_token
  end

  def last_refresh
    @oauth_client.issued_at
  end

  #
  # Setters
  #

  def access_token=(new_access_token)
    @oauth_client.access_token = new_access_token
    write_attribute(:access_token, new_access_token)
  end

  def refresh_token=(new_refresh_token)
    @oauth_client.refresh_token = new_refresh_token
    write_attribute(:refresh_token, refresh_token)
  end

  def last_refresh=(new_last_refresh)
    @oauth_client.issued_at = new_last_refresh
    write_attribute(:last_refresh, new_last_refresh)
  end

  ##
  # Fetches new tokens using the specified authorization
  # code.
  #
  # @param [String] code - authorization code from Google
  def fetch_new_tokens!(code)
    @oauth_client.code = code
    @oauth_client.fetch_access_token!
    self.access_token = @oauth_client.access_token
    self.refresh_token = @oauth_client.refresh_token
    self.last_refresh = @oauth_client.issued_at
  end

  ##
  # Fetches new access_token using the saved refresh_token
  def refresh_tokens!
    @oauth_client.fetch_access_token!
    self.access_token = @oauth_client.access_token
    self.last_refresh = @oauth_client.issued_at
    self.save
  end

  ##
  # Update user information from Google
  def update_user_info!
    response = oauth_client.fetch_protected_resource(
      :uri => "https://www.googleapis.com/oauth2/v1/userinfo?alt=json"
    )

    user_data = JSON.parse response.body
    hash_data = "%{google_id};%{name};%{email}" % {
      :google_id => user_data['id'],
      :name => user_data['name'],
      :email => user_data['email']
    }

    self.email = user_data['email']
    self.name = user_data['name']
    self.user_hash = Digest::MD5.hexdigest(hash_data)
  end

  ##
  # Add new contact
  #
  # @param [Hash] contact_info
  #   The information of the contact to add
  #   - :first_name - First name (required)
  #   - :last_name - Last name (required)
  #   - :phone - Phone number (required)
  def add_contact(contact_info)
    if self.needs_refresh?
      self.refresh_tokens!
    end

    request_body = NEW_CONTACT_FORMAT % {
      :first_name => contact_info[:first_name],
      :last_name => contact_info[:last_name],
      :phone => contact_info[:phone],
      :user_email => self.email
    }

    response = @oauth_client.fetch_protected_resource(
      :uri => "https://www.google.com/m8/feeds/contacts/default/full",
      :body => request_body,
      :headers => {
        'Content-type' => 'application/atom+xml',
        'GData-Version' => '3.0'
      },
      :method => "POST"
    )
  end

  ##
  # Checks if the access token needs an update
  def needs_refresh?
    last_refresh + 3600 <= Time.now.to_i
  end

  ##
  # Initialize the OAuth client for this user
  private
  def init_oauth_client
    @oauth_client = new_auth_client

    @oauth_client.access_token = read_attribute(:access_token)
    @oauth_client.refresh_token = read_attribute(:refresh_token)
    @oauth_client.issued_at = read_attribute(:last_refresh)
  end

  ##
  # Get a new Signet::OAuth2::Client
  private
  def new_auth_client
    client = Signet::OAuth2::Client.new(
      :authorization_uri    => Yetting.google_auth_uri,
      :token_credential_uri => Yetting.google_token_uri,
      :client_id            => Yetting.google_client_id,
      :client_secret        => Yetting.google_client_secret,
      :redirect_uri         => Yetting.google_callback,
      :scope                => Yetting.google_api_scopes
    )
  end
end
