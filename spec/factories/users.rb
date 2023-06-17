FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "Name #{n}" }
    provider { "spotify" }
    uid { "username_spotify" }
    access_token { "access_token" }
    refresh_token { "refresh_token" }
  end
end
