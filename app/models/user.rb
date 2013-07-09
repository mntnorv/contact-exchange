class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :omniauthable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauth_providers => [:google_oauth2]

  def self.from_omniauth(auth)
    /#if user = User.find_by_email(auth.info.email)
      user.provider = auth.provider
      user.user_id = auth.uid
      user
    else
      where(auth.slice(:provider, :user_id)).first_or_create do |user|
        user.provider = auth.provider
        user.user_id = auth.uid
        user.name = auth.info.name
        user.email = auth.info.email
      end
    end#/
    if user = User.find_by_email(auth.info.email)
      user.access_token = auth.credentials.token
      user.access_token_expires_at = auth.credentials.expires_at
      #user.refresh_token = auth.credentials.refresh_token
      user.save
    else
      user = User.create(
        name: auth.info.name,
        email: auth.info.email,
        password: Devise.friendly_token[0,20],
        access_token: auth.credentials.token,
        access_token_expires_at: auth.credentials.expires_at,
        refresh_token: auth.credentials.refresh_token,
        long_token: Devise.friendly_token[0,24]
      )
    end

    user
  end
end
