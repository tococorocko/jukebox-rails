require "sidekiq/web"

Rails.application.routes.draw do
  resources :jukeboxes

  root to: "users#show"

  devise_for :users, controllers: {
    sessions: "users/sessions",
    omniauth_callbacks: "users/omniauth_callbacks"
  }
  get "download/:jukebox_id", action: :download, controller: "users", as: :download
  get "gallery/:jukebox_id", action: :gallery, controller: "users", as: :gallery

  get "credits/:jukebox_id", action: :credits, controller: "jukeboxes"
  get "add-song/:jukebox_id/:song_id", action: :add_song, controller: "jukeboxes"
  get "playing-song/:jukebox_id", action: :playing_song, controller: "jukeboxes"
  get "next-song/:jukebox_id", action: :next_song, controller: "jukeboxes"
  get "control-playback/:jukebox_id", action: :control_playback, controller: "jukeboxes"
  post "take-photo/:jukebox_id", action: :take_photo, controller: "jukeboxes"

  authenticate :user do
    mount Sidekiq::Web => "/sidekiq-dashboard"
  end
end
