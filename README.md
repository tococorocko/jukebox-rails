# README

Spotify-Jukebox https://photo-jukebox.herokuapp.com/

Sidekiq: https://photo-jukebox.herokuapp.com/sidekiq-dashboard

Ruby version: ruby '3.1'
Rails version: rails '~> 7.0.0'

** Configuration

Database creation
bundle exec rails db:create
bundle exec rails db:migrate
bundle exec rails db:seed

TODO: How to run the test suite
bundle exec rspec

Deployment instructions
git push main
git push heroku main
heroku run rake db:migrate heroku run rake db:seed
heroku open

** Commands

Run dev server:

`bin/dev`

Build assets:

`npm run build`

Install packages:

`npm install`

Install Gems:

`bundle install`

Install Redis (background job zip-creation):
`brew install redis`

`redis-server`

On Heroku:

- paid sidekiq worker necessary