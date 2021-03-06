class User < ActiveRecord::Base

  before_create :generate_authentication_token!

  has_many :labels, dependent: :destroy
  has_many :cards, dependent: :destroy

  validates :auth_token_for_web, uniqueness: true
  
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  def generate_authentication_token!
    begin
      token = Devise.friendly_token
    end while User.exists?(auth_token_for_web: token)

    self.auth_token_for_web = token
  end

  def generate_authentication_token_for_chrome
    begin
      token = Devise.friendly_token
    end while User.exists?(auth_token_for_chrome: token)

    self.auth_token_for_chrome = token
  end
end
