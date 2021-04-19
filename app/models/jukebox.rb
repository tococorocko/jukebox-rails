class Jukebox < ApplicationRecord
  belongs_to :user
  belongs_to :device
  belongs_to :playlist
  has_many :songs, dependent: :destroy
  has_many :queued_songs, dependent: :destroy
  has_many_attached :images
end
