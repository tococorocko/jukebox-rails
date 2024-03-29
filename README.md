
![RSpec and Rubocop](https://github.com/tococorocko/jukebox-rails/actions/workflows/rubyonrails.yml/badge.svg)

# README

Spotify-Jukebox: https://spotify-jukebox.up.railway.app/

Sidekiq: https://spotify-jukebox.up.railway.app/sidekiq-dashboard

Ruby version: ruby "3.1"

Rails version: rails "~> 7.0.0"

## Configuration

Database creation

```
bundle exec rails db:create
bundle exec rails db:migrate
bundle exec rails db:seed
```

## Deployment Railway

- Changes to main branch are automaticall deployed to https://railway.app/


## Commands

### Run dev server:

`bin/dev`

### Build assets:

`npm run build`

### Install packages:

`npm install`

### Install Gems:

`bundle install`

### Install Redis (background job zip-creation):

`brew install redis`

`redis-server`


### Rspec:
`bundle exec rspec`

### Rubocop:
`bundle exec rubocop`

or to auto-generate config file:

`rubocop --auto-gen-config`

### Secrets

`EDITOR="code --wait" bin/rails credentials:edit`

#### Example credentials.yml.enc

```yml
aws:
  access_key_id: "..."
  secret_access_key: ""..."
  region: eu-central-1
  dev:
    bucket: "..."
  prod:
    bucket: "..."
spotify:
  client_id: "..."
  client_secret: "..."
# Used as the base secret for all MessageVerifiers in Rails, including the one protecting cookies.
secret_key_base: "..."
```

## Railway.app commands examples

    # Connect railway.app (only once)
    railway link

    # Use CLI
    railway run bash

    # Check logs
    railway logs

    # Example binary command
    railway run bin/rails db:create

### Legacy

## Deployment instructions (Legacy Heroku)


Spotify-Jukebox: https://photo-jukebox.herokuapp.com/

Sidekiq: https://photo-jukebox.herokuapp.com/sidekiq-dashboard

```
git push main
git push heroku main
heroku run rake db:migrate heroku run rake db:seed
heroku open
```

Paid sidekiq worker necessary for BackgroundJob to generate zip

