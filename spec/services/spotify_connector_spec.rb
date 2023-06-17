require "rails_helper"

RSpec.describe SpotifyConnector, type: :service do
  describe ".fetch_active_devices" do
    let(:user) { create(:user) }

    it "fetches and creates devices for the user" do
      stub_device_request

      expect do
        SpotifyConnector.fetch_active_devices(user)
      end.to change(Device, :count).by(2)

      expect(user.devices.pluck(:device_uid)).to match_array(%w[device1 device2])
    end

    it "returns nil if the API request is not successful" do
      stub_device_request(return_status: 500, with_body: false)

      expect(SpotifyConnector.fetch_active_devices(user)).to be_nil
    end
  end

  describe ".fetch_playlists" do
    let(:user) { create(:user) }

    it "fetches and creates playlists for the user" do
      stub_playlist_request(user:)

      expect { SpotifyConnector.fetch_playlists(user)}.to change(Playlist, :count).by(2)
      expect(user.playlists.pluck(:playlist_uid)).to match_array(%w[playlist1 playlist2])
    end

    it "returns nil if the API request is not successful" do
      stub_playlist_request(user:, return_status: 500, with_body: false)
      expect(SpotifyConnector.fetch_playlists(user)).to be_nil
    end
  end

  describe ".fetch_songs" do
    let(:user) { create(:user) }
    let(:device) { create(:device, user: user) }
    let(:playlist) { create(:playlist, user: user) }
    let(:jukebox) { create(:jukebox, user: user, device: device, playlist: playlist) }
    let(:limit) { 100 }
    let(:offset) { 0 }

    it "fetches and creates songs for the jukebox" do
      stub_fetch_song(playlist_uid: playlist.playlist_uid, limit: limit, offset: offset)
      expect { SpotifyConnector.fetch_songs(jukebox)}.to change(Song, :count).by(2)
      expect(jukebox.songs.pluck(:uri)).to match_array(%w[song1 song2])
    end

    it "returns nil if the API request is not successful" do
      stub_fetch_song(playlist_uid: playlist.playlist_uid, limit: limit, offset: offset, return_status: 500, with_body: false)

      expect(SpotifyConnector.fetch_songs(jukebox)).to eq([])
    end
  end

  describe ".fetch_playing_song" do
    let(:user) { create(:user) }

    context "when the response is successful and a song is playing" do
      it "returns the playing song information" do
        stub_fetch_playing_song()
        song_info = SpotifyConnector.fetch_playing_song(user)

        expect(song_info).to eq(
          {
            name: "Song Name - Artist Name",
            cover_uri: "https://example.com/cover.jpg",
            uri: "spotify:track:123456"
          }
        )
      end
    end

    context "when the response is successful but no song is playing" do
      it "returns a default waiting message" do
        stub_fetch_playing_song(is_playing: false)
        song_info = SpotifyConnector.fetch_playing_song(user)

        expect(song_info).to eq({ name: "Waiting for first Song", cover_uri: "" })
      end
    end

    context "when the response is not successful and token needs to be refreshed" do
      it "refreshes the token and raises ApiNotAvailable exception (only in specs!)" do
        stub_fetch_playing_song(return_status: 401)
        stub_refresh_token(return_status: 401, with_body: false)
        expect { SpotifyConnector.fetch_playing_song(user) }.to raise_error(SpotifyConnector::ApiNotAvailable)
      end
    end
  end

  describe ".add_song_to_queue" do
    let(:user) { create(:user) }
    let(:device) { create(:device, user: user) }
    let(:jukebox) { create(:jukebox, user: user, device: device) }
    let(:song) { create(:song, jukebox: jukebox) }

    before do
      allow(HTTParty).to receive(:post).and_return(double(success?: true, unauthorized?: false))
      allow(QueuedSong).to receive(:create)
    end

    it "adds the song to the queue and returns the queued song" do
      expect(HTTParty).to receive(:post)
        .with(
          "https://api.spotify.com/v1/me/player/queue?uri=#{song.uri}",
          {
            headers: {
              "Accept" => "application/json",
              "Content-Type" => "application/json",
              "Authorization" => "Bearer #{user.access_token}"
            }
          }
        )
        .and_return(double(success?: true, unauthorized?: false))
      queued_song = SpotifyConnector.add_song_to_queue(jukebox, song)

      expect(queued_song).to be_a(QueuedSong)
    end

    context "when the API request is not successful" do
      before do
        allow(HTTParty).to receive(:post).and_return(double(success?: false, unauthorized?: false))
      end

      it "returns nil" do
        queued_song = SpotifyConnector.add_song_to_queue(jukebox, song)

        expect(queued_song).to be_nil
      end
    end
  end

  describe ".play_next_song" do
    let(:user) { build(:user) }

    context "when the request is successful" do
      before do
        allow(HTTParty).to receive(:post).and_return(double(success?: true, unauthorized?: false))
      end

      it "returns nil" do
        response = SpotifyConnector.play_next_song(user)
        expect(response).to be_nil
      end

      it "sends a request to play the next song" do
        expect(HTTParty).to receive(:post).with(
          "https://api.spotify.com/v1/me/player/next",
          {
            headers: {
              "Accept" => "application/json",
              "Content-Type" => "application/json",
              "Authorization" => "Bearer #{user.access_token}"
            }
          }
        ).and_return(double(success?: true))

        SpotifyConnector.play_next_song(user)
      end
    end

    context "when the request is not successful" do
      before do
        allow(HTTParty).to receive(:post).and_return(double(success?: false, unauthorized?: false))
      end

      it "returns nil" do
        response = SpotifyConnector.play_next_song(user)
        expect(response).to be_nil
      end
    end
  end

  describe ".refresh_token" do
    let(:user) { create(:user) }

    context "when the request is successful" do
      let(:client_id) { "your_client_id" }
      let(:client_secret) { "your_client_secret" }
      let(:auth) { Base64.urlsafe_encode64("#{client_id}:#{client_secret}") }
      let(:access_token) { "1234" }
      let(:new_refresh_token) { "5678" }

      it "updates the access_token and refresh_token of the user" do
        stub_refresh_token
        expect(user).to receive(:update).with(access_token: access_token)
        expect(user).to receive(:update).with(refresh_token: new_refresh_token)

        refreshed_user = SpotifyConnector.refresh_token(user)
        expect(refreshed_user).to eq(user)
      end
    end

    context "when the request is not successful" do
      it "raises an exception" do
        stub_refresh_token(return_status: 500, with_body: false)
        expect { SpotifyConnector.refresh_token(user) }.to raise_error(SpotifyConnector::ApiNotAvailable)
      end
    end
  end

  describe ".song_request" do
    let(:jukebox) { create(:jukebox) }
    let(:playlist_uid) { "playlist_uid" }
    let(:limit) { 100 }
    let(:offset) { 0 }
    let(:access_token) { "access_token" }

    context "when the request is successful" do
      it "returns the parsed items" do
        stub_fetch_song(playlist_uid: playlist_uid, limit: limit, offset: offset)
        parsed_items = [{"track"=>{"name"=>"Song 1", "uri"=>"song1", "artist"=>"Artist A"}}, {"track"=>{"name"=>"Song 2", "uri"=>"song2", "artist"=>"Artist B"}}]

        result = SpotifyConnector.song_request(jukebox, playlist_uid, limit, offset)

        expect(result).to eq(parsed_items)
      end
    end

    context "when the request is not successful" do
      it "returns nil" do
        stub_fetch_song(playlist_uid: playlist_uid, limit: limit, offset: offset, return_status: 500, with_body: false)
        result = SpotifyConnector.song_request(jukebox, playlist_uid, limit, offset)

        expect(result).to be_nil
      end
    end
  end

  describe ".create_devices" do
    let(:devices) { [{ "id" => "device_id", "name" => "Device 1" }, { "id" => "device_id_2", "name" => "Device 2" }] }
    let(:user) { create(:user) }

    context "when the device already exists" do
      let!(:existing_device) { create(:device, device_uid: "device_id", user: user) }

      it "updates the existing device's updated_at timestamp" do
        expect { SpotifyConnector.create_devices(devices, user) }.to change { existing_device.reload.updated_at }
      end
    end

    context "when the device does not exist" do
      it "creates a new device" do
        expect { SpotifyConnector.create_devices(devices, user) }.to change { Device.count }.by(2)
      end
    end

    it "destroys devices that haven't been updated in the last minute" do
      create(:device, device_uid: "device_id_3", user: user, updated_at: 2.minutes.ago)

      expect { SpotifyConnector.create_devices(devices, user) }.to change { Device.count }.by(1)
    end
  end

  describe ".create_playlists" do
    let(:playlists) {
      [{ "id" => "playlist_id_1", "name" => "Playlist 1", "tracks" => { "href" => "tracks_url", "total" => 10 } },
       { "id" => "playlist_id_2", "name" => "Playlist 2", "tracks" => { "href" => "tracks_url", "total" => 5 } }]
    }
    let(:user) { create(:user) }

    before do
      Playlist.destroy_all
    end

    it "creates new playlists" do
      expect { SpotifyConnector.create_playlists(playlists, user) }.to change { Playlist.count }.by(2)
    end

    it "deletes existing playlists for the user" do
      create(:playlist, user:)

      expect { SpotifyConnector.create_playlists(playlists, user) }.to change { Playlist.count }.by(1)
    end
  end

  describe ".create_songs" do
    let(:songs) do
      [
        {
          "track" => {
            "name" => "Song 1",
            "artists" => [{ "name" => "Artist 1" }],
            "uri" => "song_uri_1",
            "album" => {
              "images" => [{ "url" => "cover_uri_1" }]
            },
            "duration_ms" => 180000
          }
        },
        {
          "track" => {
            "name" => "Song 2",
            "artists" => [{ "name" => "Artist 2" }],
            "uri" => "song_uri_2",
            "album" => {
              "images" => [{ "url" => "cover_uri_2" }]
            },
            "duration_ms" => 240000
          }
        }
      ]
    end

    let(:jukebox) { create(:jukebox) }

    context "when the song already exists" do
      let!(:existing_song) { create(:song, jukebox:, name: "Song 1") }

      it "updates the existing song's updated_at timestamp" do
        expect { SpotifyConnector.create_songs(songs, jukebox) }.to change { existing_song.reload.updated_at }
      end
    end

    context "when the song does not exist" do
      it "creates a new song" do
        expect { SpotifyConnector.create_songs(songs, jukebox) }.to change { Song.count }.by(2)
      end
    end

    it "destroys songs that haven't been updated in the last minute" do
      create(:song, jukebox:, updated_at: 2.minutes.ago)

      expect { SpotifyConnector.create_songs(songs, jukebox) }.to change { Song.count }.by(1)
    end
  end
end
