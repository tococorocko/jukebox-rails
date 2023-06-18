module SpotifyStubs
  def stub_playlist_request(return_status: 200, with_body: true)
    body = []
    if with_body
      body = {
        items: [
          { name: "Playlist 1", id: "playlist1", tracks: { href: "tracks_url", total: 10 } },
          { name: "Playlist 2", id: "playlist2", tracks: { href: "tracks_url", total: 5 } }
        ]
      }
    end
    stub_request(:get, "https://api.spotify.com/v1/me/playlists?limit=50")
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
          { id: "device1", name: "Device 1", is_active: true, is_private_session: false, is_restricted: false, type: "computer", volume_percent: 100 },
          { id: "device2", name: "Device 2", is_active: false, is_private_session: false, is_restricted: false, type: "smartphone", volume_percent: 100 }
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
    stub_request(:get, "https://api.spotify.com/v1/playlists/#{playlist_uid}/tracks?limit=#{limit}&offset=#{offset}&fields=items(track(name,uri,duration_ms,album(images),artists(name)))")
      .to_return(
        status: return_status,
        body: body.to_json
      )
  end

  def stub_fetch_currently_playing_and_queue(return_status: 200, with_body: true)
    body = {
      currently_playing: {
        name: "Waiting for first Song",
        cover_uri: "",
        uri: ""
      },
      queue: []
    }
    if with_body
      body[:currently_playing] = {
          name: "Song Name",
          uri: "spotify:track:123456",
          artists: [{ name: "Artist Name" }],
          album: {
            images: [{ url: "https://example.com/cover.jpg" }]
          }
      }
      body[:queue] = [
        { name: "Song 1", uri: "spotify:track:123456", artists: [{name: "Artist 1"}], album: { images: [{ url: "https://example.com/cover1.jpg" }] } },
        { name: "Song 2", uri: "spotify:track:123457", artists: [{name: "Artist 2"}], album: { images: [{ url: "https://example.com/cover2.jpg" }] } },
        { name: "Song 3", uri: "spotify:track:123458", artists: [{name: "Artist 3"}], album: { images: [{ url: "https://example.com/cover3.jpg" }] } },
        { name: "Song 4", uri: "spotify:track:123459", artists: [{name: "Artist 4"}], album: { images: [{ url: "https://example.com/cover4.jpg" }] } },
        { name: "Song 5", uri: "spotify:track:123460", artists: [{name: "Artist 5"}], album: { images: [{ url: "https://example.com/cover5.jpg" }] } },
      ]
    end
    stub_request(:get, "https://api.spotify.com/v1/me/player/queue")
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

  def stub_add_song_to_queue(jukebox:, song:, return_status: 204)
    stub_request(:post, "https://api.spotify.com/v1/me/player/queue?uri=#{song.uri}&device_id=#{jukebox.device.device_uid}")
      .to_return(
        status: return_status,
      )
  end

  def stub_play_next_song(return_status: 204)
    stub_request(:post, "https://api.spotify.com/v1/me/player/next")
      .to_return(
        status: return_status
      )
  end
end
