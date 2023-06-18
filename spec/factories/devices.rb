FactoryBot.define do
  factory :device do
    device_uid { "device_uid" }
    name { "Device Name" }
    user
  end
end
