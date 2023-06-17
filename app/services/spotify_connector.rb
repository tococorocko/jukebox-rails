require "base64"

class SpotifyConnector < ApplicationService
  class ApiNotAvailable < StandardError; end

  class ExpiredAccessToken < ApiNotAvailable; end

  def self.fetch_active_devices(user)
    response = HTTParty.get(
      "https://api.spotify.com/v1/me/player/devices",
      {
        headers: default_request_header(user.access_token)
      }
    )
    raise ExpiredAccessToken if response.unauthorized?
    return nil unless response.success?

    parsed_response = JSON.parse(response.body)["devices"]
    create_devices(parsed_response, user)
  rescue ExpiredAccessToken
    user = refresh_token(user)
    fetch_active_devices(user)
  end

  def self.fetch_playlists(user)
    response = HTTParty.get(
      "https://api.spotify.com/v1/users/#{user.uid}/playlists",
      {
        headers: default_request_header(user.access_token)
      }
    )
    raise ExpiredAccessToken if response.unauthorized?
    return nil unless response.success?

    parsed_response = JSON.parse(response.body)["items"]
    create_playlists(parsed_response, user)
  rescue ExpiredAccessToken
    user = refresh_token(user)
    fetch_playlists(user)
  end

  def self.fetch_songs(jukebox)
    playlist = jukebox.playlist
    parsed_response = []
    necessary_requests = playlist.track_number / 100 + 1 # max 100 songs per request
    limit = 100
    offset = 0
    necessary_requests.times do |_request|
      parsed_response.push(song_request(jukebox, playlist.playlist_uid, limit, offset))
      offset += 100
    end
    create_songs(parsed_response.flatten, jukebox)
  end

  def self.fetch_playing_song(user)
    response = HTTParty.get(
      "https://api.spotify.com/v1/me/player/currently-playing",
      {
        headers: default_request_header(user.access_token)
      }
    )
    raise ExpiredAccessToken if response.unauthorized?

    parsed_response = JSON.parse(response.body) rescue nil

    if parsed_response && parsed_response["is_playing"] == true
      song = parsed_response["item"]
      { name: song["name"] + " - " + song["artists"][0]["name"], cover_uri: song["album"]["images"][0]["url"],
        uri: song["uri"] }
    else
      { name: "Waiting for first Song", cover_uri: "" }
    end
  rescue ExpiredAccessToken
    user = refresh_token(user)
    fetch_playing_song(user)
  end

  def self.add_song_to_queue(jukebox, song)
    query = { uri: song.uri }.to_query

    response = HTTParty.post(
      "https://api.spotify.com/v1/me/player/queue?#{query}",
      {
        headers: default_request_header(jukebox.user.access_token)
      }
    )
    raise ExpiredAccessToken if response.unauthorized?
    return nil unless response.success?

    QueuedSong.create!(song:, jukebox:, song_uri: song.uri)
  rescue ExpiredAccessToken
    refresh_token(jukebox.user)
    add_song_to_queue(jukebox, song)
  end

  def self.play_next_song(user)
    response = HTTParty.post(
      "https://api.spotify.com/v1/me/player/next",
      {
        headers: default_request_header(user.access_token)
      }
    )
    return nil unless response.success?
  end

  def self.refresh_token(user)
    byebug
    client_id = Rails.application.credentials.spotify[:client_id]
    client_secret = Rails.application.credentials.spotify[:client_secret]
    auth = Base64.urlsafe_encode64("#{client_id}:#{client_secret}")

    response = HTTParty.post(
      "https://accounts.spotify.com/api/token",
      {
        headers: {
          "Content-Type" => "application/x-www-form-urlencoded",
          "Authorization" => "Basic #{auth}"
        },
        body: "grant_type=refresh_token&refresh_token=#{user.refresh_token}"
      }
    )
    raise ApiNotAvailable unless response.success?

    parsed_response = JSON.parse(response.body)
    user.update(access_token: parsed_response["access_token"])
    user.update(refresh_token: parsed_response["refresh_token"]) if parsed_response["refresh_token"]
    user
  end

  def self.song_request(jukebox, playlist_uid, limit, offset)
    response = HTTParty.get(
      "https://api.spotify.com/v1/playlists/#{playlist_uid}/tracks?limit=#{limit}&offset=#{offset}",
      {
        headers: default_request_header(jukebox.user.access_token)
      }
    )
    raise ExpiredAccessToken if response.unauthorized?
    return nil unless response.success?

    JSON.parse(response.body)["items"]
  rescue ExpiredAccessToken
    refresh_token(jukebox.user)
    song_request(jukebox, playlist_uid, limit, offset)
  end

  def self.create_devices(devices, user)
    devices.each do |device|
      existing_device = Device.where(device_uid: device["id"], user:).last
      if Device.where(device_uid: device["id"], user:).present?
        existing_device.touch
      else
        Device.create(name: device["name"], device_uid: device["id"], user:)
      end
    end
    Device.where("devices.user_id = ? AND updated_at < ?", user, 1.minutes.ago).destroy_all
  end

  def self.create_playlists(playlists, user)
    Playlist.where("playlists.user_id = ?", user).destroy_all

    playlists.each do |list|
      Playlist.create(name: list["name"], playlist_uid: list["id"], uri: list["tracks"]["href"],
                      track_number: list["tracks"]["total"], user:)
    end
  end

  def self.create_songs(songs, jukebox)
    songs.each do |song|
      name = song["track"]["name"] rescue ""
      existing_song = Song.where(jukebox:, name:).last
      if existing_song.present?
        existing_song.touch
      else
        artist = song["track"]["artists"][0]["name"] rescue ""
        uri = song["track"]["uri"] rescue ""
        cover_uri = song["track"]["album"]["images"][0]["url"] rescue ""
        length = song["track"]["duration_ms"] rescue ""
        Song.create(name:, artist:, uri:, cover_uri:, length:, jukebox:)
      end
    end
    jukebox.songs.where("updated_at < ?", 1.minutes.ago).destroy_all
  end

  def self.default_request_header(access_token)
    {
      "Accept" => "application/json",
      "Content-Type" => "application/json",
      "Authorization" => "Bearer #{access_token}"
    }
  end
end
