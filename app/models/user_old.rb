require 'json'

class User < ActiveRecord::Base

  NEW_CONTACT_FORMAT = "<atom:entry xmlns:atom='http://www.w3.org/2005/Atom' xmlns:gContact='http://schemas.google.com/contact/2008' xmlns:gd='http://schemas.google.com/g/2005'><atom:category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/contact/2008#contact'/><gd:name><gd:givenName>%{first_name}</gd:givenName><gd:familyName>%{last_name}</gd:familyName></gd:name><gd:phoneNumber rel='http://schemas.google.com/g/2005#mobile' primary='true'>%{phone}</gd:phoneNumber><gContact:groupMembershipInfo deleted='false' href='http://www.google.com/m8/feeds/groups/%{user_email}/base/6'/></atom:entry>"

  # Initialize the OAuth client after ActiveRecord initialization
  after_initialize :init_oauth_client

  # Generate a unique token for each user
  before_create :generate_token

  # ActiveRecord fields
  # attr_accessible :access_token, :email, :expires_in, :last_refresh, :name, :refresh_token, :user_token
  
  # The user's OAuth client
  attr_accessor :oauth_client

  # ActiveRecord data validations
  validates :access_token,  :presence => true
  validates :email,         :presence => true,
                            :uniqueness => true
  validates :expires_in,    :presence => true
  validates :last_refresh,  :presence => true
  validates :name,          :presence => true
  validates :refresh_token, :presence => true

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
    write_attribute :access_token, @oauth_client.access_token
    write_attribute :refresh_token, @oauth_client.refresh_token
    write_attribute :last_refresh, @oauth_client.issued_at
    write_attribute :expires_in, @oauth_client.expires_in
  end

  ##
  # Fetches new access_token using the saved refresh_token
  def refresh_tokens!
    @oauth_client.fetch_access_token!
    write_attribute :access_token, @oauth_client.access_token
    write_attribute :last_refresh, @oauth_client.issued_at
    write_attribute :expires_in, @oauth_client.expires_in
    self.save!
  end

  ##
  # Update user information from Google
  def update_user_info!
    response = oauth_client.fetch_protected_resource(
      :uri => "https://www.googleapis.com/oauth2/v1/userinfo?alt=json"
    )

    user_data = JSON.parse response.body

    write_attribute :email, user_data['email']
    write_attribute :name, user_data['name']
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
    # refresh only when needed
    self.refresh_tokens!

    request_body = NEW_CONTACT_FORMAT % {
      :first_name => contact_info[:first_name],
      :last_name => contact_info[:last_name],
      :phone => contact_info[:phone],
      :user_email => email
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
    @oauth_client.expired?
  end

  ##
  # Generate a unique user token
  protected
  def generate_token
    new_user_token = loop do
      random_token = SecureRandom.urlsafe_base64(24)
      break random_token unless User.where(user_token: random_token).exists?
    end
    write_attribute :user_token, new_user_token
  end

  ##
  # Initialize the OAuth client for this user
  private
  def init_oauth_client
    @oauth_client = new_auth_client

    if read_attribute(:access_token)
      @oauth_client.access_token = read_attribute(:access_token)
    end

    if read_attribute(:refresh_token)
      @oauth_client.refresh_token = read_attribute(:refresh_token)
    end

    if read_attribute(:last_refresh)
      @oauth_client.issued_at = read_attribute(:last_refresh)
    end
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
