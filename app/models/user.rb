require 'oauth2'
require 'haml'

class User < ActiveRecord::Base

  # The format string of a new Google contact entry
  TEMPLATES_DIR = File.join(Rails.root, 'config', 'templates')

  # Initialize the OAuth client after ActiveRecord initialization
  after_initialize :init_oauth_access_token

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :omniauthable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauth_providers => [:google_oauth2]

  validates_confirmation_of :password

  # The user's OAuth client
  attr_reader :oauth_access_token
  attr_reader :response

  ##################################################
  # Instance methods
  ##################################################

  ##
  # Refreshes the user's access token if it has expired
  # and saves it to the database.
  def refresh_access_token!
    if @oauth_access_token.expired?
      @oauth_access_token = @oauth_access_token.refresh!
      write_attribute :access_token, @oauth_access_token.token
      write_attribute :access_token_expires_at, @oauth_access_token.expires_at
      self.save!
    end
  end

  ##
  # Add new contact to this user's Google contact list
  #
  # @param [Hash] contact_info
  #   The information of the contact to add
  #   - :first_name - First name (required)
  #   - :last_name - Last name (required)
  #   - :phone - Phone number (required)
  # @yield the response status code
  def add_contact(contact_info)
    self.refresh_access_token!

    contact = OpenStruct.new({
      first_name: contact_info[:first_name],
      last_name: contact_info[:last_name],
      phone: contact_info[:phone]
    })

    haml_template = File.read(File.join(TEMPLATES_DIR, 'contact.xml.haml'))
    request_body = Haml::Engine.new(haml_template).render(Object.new, {
      contact: contact,
      user: self
    })

    p request_body

    @response = @oauth_access_token.post(
      'https://www.google.com/m8/feeds/contacts/default/full',
      {
        body: request_body,
        headers: {
          'Content-type' => 'application/atom+xml',
          'GData-Version' => '3.0'
        }
      }
    )

    @response.status == 201
  end

  ##
  # Enables sign up without a password
  def password_required?
    false
  end

  ##################################################
  # Private instance methods
  ##################################################

  private

  ##
  # Initializes the OAuth2 access token object for this user
  def init_oauth_access_token
    @oauth_access_token = OAuth2::AccessToken.new(
      User.new_oauth_client,
      read_attribute(:access_token),
      {
        :refresh_token => read_attribute(:refresh_token),
        :expires_at => read_attribute(:access_token_expires_at)
      }
    )
  end

  ##################################################
  # Class methods
  ##################################################

  ##
  # Finds a user by his login email (from Omniauth).
  # If a user is not found, creates a new user using the data
  # from Omniauth. Always returns a user.
  #
  # @param [Hash] auth
  #   The omniauth login information
  def self.from_omniauth(auth)
    if user = User.find_by_email(auth.info.email)
      user.access_token = auth.credentials.token
      user.access_token_expires_at = auth.credentials.expires_at
      user.save
    else
      user = User.create(
        name: auth.info.name,
        email: auth.info.email,
        access_token: auth.credentials.token,
        access_token_expires_at: auth.credentials.expires_at,
        refresh_token: auth.credentials.refresh_token,
        long_token: Devise.friendly_token[0,24]
      )
    end

    user
  end

  ##
  # Get a new OAuth2 client
  def self.new_oauth_client
    client = OAuth2::Client.new(
      Yetting.google_client_id,
      Yetting.google_client_secret,
      {
        :authorize_url => Yetting.google_auth_uri,
        :token_url => Yetting.google_token_uri
      }
    )
  end
end
