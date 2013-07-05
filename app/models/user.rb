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
    user = User.find_by_email(auth.info.email)

    unless user
      user = User.create(
        user_id: auth.uid,
        provider: auth.provider,
        name: auth.info.name,
        email: auth.info.email,
        password: "abcdefgh"
      )
    end

    user
  end
end
