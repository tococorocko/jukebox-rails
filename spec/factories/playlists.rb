FactoryBot.define do
  factory :playlist do
    name { "Playlist Name" }
    playlist_uid { "playlist_uid" }
    track_number { 0 }
    user
  end
end
