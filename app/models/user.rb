require 'oauth2'
require 'haml'
require 'nokogiri'

class User < ActiveRecord::Base

  # The format string of a new Google contact entry
  TEMPLATES_DIR  = File.join(Rails.root, 'config', 'templates')
  GROUP_REGEX    = /https:\/\/www.google.com\/m8\/feeds\/groups\/[a-z%\d\.\-]+\/full\/([a-f\d]+)/
  ATOM_NAMESPACE = 'http://www.w3.org/2005/Atom'

  # Initialize the model after ActiveRecord initialization
  after_initialize :init

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :omniauthable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauth_providers => [:google_oauth2]

  validates :password, confirmation: true

  # The user's OAuth client
  attr_reader :oauth_access_token
  attr_reader :response

  ##################################################
  # Instance methods
  ##################################################

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
    request_body = Haml::Engine.new(haml_template, remove_whitespace: true).render(Object.new, {
      contact: contact,
      user: self
    })

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
  # Refreshes the user's access token if it has expired.
  def refresh_access_token
    return false unless @oauth_access_token.expired?

    @oauth_access_token = @oauth_access_token.refresh!
    write_attribute :access_token, @oauth_access_token.token
    write_attribute :access_token_expires_at, @oauth_access_token.expires_at
    true
  end

  ##
  # Refreshes the user's access token if it has expired
  # and saves it to the database.
  def refresh_access_token!
    self.save! if refresh_access_token
  end

  ##
  # Refreshes the user's Contact Exchange group id.
  def refresh_ce_group
    return false if ce_group_valid?

    group_id = existing_ce_group || add_ce_group
    return false unless group_id

    write_attribute :group_id, group_id
    true
  end

  ##
  # Refreshes the user's Contact Exchange group id and saves it to the
  # database.
  def refresh_ce_group!
    self.save! if refresh_ce_group
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
  # Initialize a new instance of this class
  def init
    init_oauth_access_token
  end

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

  ##
  # Check this user's Contact Exchange group is valid
  def ce_group_valid?
    return false unless self.group_id
    self.refresh_access_token!

    @oauth_access_token.get(
      "https://www.google.com/m8/feeds/groups/default/full/#{self.group_id}",
      {
        headers: {
          'Content-type' => 'application/atom+xml',
          'GData-Version' => '3.0'
        }
      }
    )

    true  # group is valid
  rescue OAuth2::Error
    false # group is invalid
  end

  ##
  # Check if user already has a Contact Exchange group.
  #
  # @yield the Google contacts group id if the user has a Contact Exchange
  #   group, nil otherwise
  def existing_ce_group
    self.refresh_access_token!

    response = @oauth_access_token.get(
      'https://www.google.com/m8/feeds/groups/default/full?max-results=100000',
      {
        headers: {
          'Content-type' => 'application/atom+xml',
          'GData-Version' => '3.0'
        }
      }
    ).body

    doc = Nokogiri::XML(response)

    ids = doc.xpath('//atom:entry/atom:id', {'atom' => ATOM_NAMESPACE}).map do |e|
      e.content.split('/')[-1]
    end

    titles = doc.xpath('//atom:entry/atom:title', {'atom' => ATOM_NAMESPACE}).map do |e|
      e.content
    end

    entries = Hash[titles.zip(ids)]
    entries['Contact Exchange']
  end

  ##
  # Add a new contact group and return its id
  def add_ce_group
    self.refresh_access_token!

    haml_template = File.read(File.join(TEMPLATES_DIR, 'group.xml.haml'))
    request_body = Haml::Engine.new(haml_template, remove_whitespace: true).render(Object.new)

    @response = @oauth_access_token.post(
      'https://www.google.com/m8/feeds/groups/default/full',
      {
        body: request_body,
        headers: {
          'Content-type' => 'application/atom+xml',
          'GData-Version' => '3.0'
        }
      }
    )

    group_id = GROUP_REGEX.match(@response.body)[1]

    @response.status == 201 ? group_id : nil
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
