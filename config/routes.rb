Rails.application.routes.draw do
  # get 'jukeboxes/new'
  # get 'jukeboxes/create'
  # get 'jukeboxes/show'
  # get 'jukeboxes/destroy'
  resources :jukeboxes

  root to: 'users#show'

  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
  get 'download/:jukebox_id', action: :download, controller: 'users', as: :download

  get 'credits/:jukebox_id', action: :credits, controller: 'jukeboxes'
  get 'add-song/:jukebox_id/:song_id', action: :add_song, controller: 'jukeboxes'
  get 'playing-song/:jukebox_id', action: :playing_song, controller: 'jukeboxes'
  get 'queue/:jukebox_id', action: :queue, controller: 'jukeboxes'
  get 'next-song/:jukebox_id', action: :next_song, controller: 'jukeboxes'
  post 'take-photo/:jukebox_id', action: :take_photo, controller: 'jukeboxes'
end
