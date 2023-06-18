class User < ApplicationRecord
  ZIP_DIRECTORY = Rails.root.join("tmp", "zip")

  devise :database_authenticatable, :omniauthable, omniauth_providers: %i[spotify]

  has_many :jukeboxes
  has_many :songs, through: :jukeboxes
  has_many :devices, dependent: :destroy
  has_many :playlists, dependent: :destroy

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.name = auth.info.name
      user.password = Devise.friendly_token[0, 20]
    end
  end
end
