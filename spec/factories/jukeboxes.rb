FactoryBot.define do
  factory :jukebox do
    transient do
      with_attachment { false }
    end

    name { "Jukebox Name" }
    user
    device
    playlist

    after(:build) do |jukebox, evaluator|
      if evaluator.with_attachment
        filenames = ['test-img.png']
        files = filenames.map { |filename|
          Rack::Test::UploadedFile.new(Rails.root.join("spec", "fixtures", filename), 'image/png')
        }
        jukebox.images.attach(files)
      end
    end
  end
end
