class QueuedSong < ApplicationRecord
  belongs_to :jukebox
  belongs_to :song, dependent: :destroy
end
