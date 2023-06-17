source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.1.2"

# Bundle edge Rails instead: gem "rails", github: "rails/rails"
gem "rails", "~> 7.0.1"
# Use postgresql as the database for Active Record
gem "pg", ">= 0.18", "< 2.0"
# Use Puma as the app server
gem "puma", "~> 4.1"
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
# gem "turbolinks", "~> 5"
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder", "~> 2.7"
# Use Active Model has_secure_password
# gem "bcrypt", "~> 3.1.7"
gem "sprockets-rails"
# Use Active Storage variant
# gem "image_processing", "~> 1.2"

# Reduces boot times through caching; required in config/boot.rb
gem "aws-sdk-s3", require: false
gem "bootsnap", require: false
gem "devise"
gem "httparty"
gem "jsbundling-rails"
gem "omniauth-rails_csrf_protection"
gem "omniauth-spotify"
gem "rails-i18n"
gem "rspotify"
gem "rubyzip"

group :development, :test do
  # Call "byebug" anywhere in the code to stop execution and get a debugger console
  gem "byebug", platforms: %i[mri mingw x64_mingw]
  gem "debug"
  gem "rubocop-rails", require: false
  gem "webmock"
  gem "standardrb"
  gem "brakeman"
end

group :test do
  gem "factory_bot_rails"
  gem "rspec-rails", "~> 6.0.0"
  gem "rails-controller-testing"
  gem 'simplecov', require: false
end

group :development do
  # Access an interactive console on exception pages or by calling "console" anywhere in the code.
  gem "listen", "~> 3.2"
  gem "web-console"
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0.0"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "redis"
gem "sidekiq", "~> 6.5"
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]
