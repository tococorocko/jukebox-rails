FactoryBot.define do
  factory :song do
    name { "Song Name" }
    artist { "Artist Name" }
    length { 1000 }
    playing { false }
    uri { "uri" }
    jukebox
  end
end
