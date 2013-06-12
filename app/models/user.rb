class User < ActiveRecord::Base
  attr_accessible :access_token, :email, :last_refresh, :refresh_token, :user_hash

  validates :access_token,  :presence => true
  validates :email,         :presence => true
  validates :user_hash,     :presence => true,
                            :length => { :is => 32 }
  validates :last_refresh,  :presence => true
  validates :refresh_token, :presence => true
end
