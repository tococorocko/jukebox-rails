module SpotifyStubs
  def stub_playlist_request(user: user_data, return_status: 200, with_body: true)
    body = []
    if with_body
      body = {
        items: [
          { name: "Playlist 1", id: "playlist1", tracks: { href: "tracks_url", total: 10 } },
          { name: "Playlist 2", id: "playlist2", tracks: { href: "tracks_url", total: 5 } }
        ]
      }
    end
    stub_request(:get, "https://api.spotify.com/v1/users/#{user.uid}/playlists")
      .to_return(
        status: return_status,
        body: body.to_json
      )
  end

  def stub_device_request(return_status: 200, with_body: true)
    body = []
    if with_body
      body = {
        devices: [
          { id: "device1", name: "Device 1" },
          { id: "device2", name: "Device 2" }
        ]
      }
    end

    stub_request(:get, "https://api.spotify.com/v1/me/player/devices")
      .to_return(
        status: return_status,
        body: body.to_json
      )
  end

  def stub_fetch_song(playlist_uid:, limit:, offset:, return_status: 200, with_body: true)
    body = []
    if with_body
      body = {
        "items" => [
          { track: { name: "Song 1", uri: "song1", artist: "Artist A" } },
          { track: { name: "Song 2", uri: "song2", artist: "Artist B" } }
        ]
      }
    end
    stub_request(:get, "https://api.spotify.com/v1/playlists/#{playlist_uid}/tracks?limit=#{limit}&offset=#{offset}")
      .to_return(
        status: return_status,
        body: body.to_json
      )
  end

  def stub_fetch_playing_song(return_status: 200, with_body: true, is_playing: true)
    body = []
    if with_body
      body = {
        "is_playing" => is_playing,
        "item" => {
          "name" => "Song Name",
          "artists" => [{ "name" => "Artist Name" }],
          "album" => {
            "images" => [{ "url" => "https://example.com/cover.jpg" }]
          },
          "uri" => "spotify:track:123456"
        }
      }
    end
    stub_request(:get, "https://api.spotify.com/v1/me/player/currently-playing")
      .to_return(
        status: return_status,
        body: body.to_json
      )
  end

  def stub_refresh_token(return_status: 200, with_body: true)
    body = []
    if with_body
      body = {
        "access_token" => "1234",
        "refresh_token" => "5678"
      }
    end
    stub_request(:post, "https://accounts.spotify.com/api/token")
      .to_return(
        status: return_status,
        body: body.to_json
      )
  end
end
