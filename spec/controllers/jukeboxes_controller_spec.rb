require "rails_helper"

RSpec.describe JukeboxesController, type: :controller do
  let(:user) { create(:user) }
  let(:jukebox) { create(:jukebox, user:) }
  let(:song) { create(:song) }

  before { sign_in(user) }

  describe "GET #new" do
    it "assigns the necessary instance variables" do
      stub_device_request
      stub_playlist_request

      get :new
      expect(assigns(:user)).to eq(user)
      expect(assigns(:jukebox)).to be_a_new(Jukebox)
      expect(assigns(:devices)).to eq(user.devices.order(:name))
      expect(assigns(:playlists)).to eq(user.playlists.order(:name))
      expect(assigns(:cameras)).to eq([])
    end
  end

  describe "POST #create" do
    let(:jukebox_params) { attributes_for(:jukebox).merge!(additional_params) }
    let(:additional_params) { {} }

    context "with valid params" do
      let(:device) { create(:device, user: user) }
      let(:playlist) { create(:playlist, user: user) }
      let(:additional_params) { { user_id: user.id, device_id: device.id, playlist_id: playlist.id } }
      it "creates a new jukebox" do
        expect {
          post :create, params: { jukebox: jukebox_params }
        }.to change(Jukebox, :count).by(1)
      end

      it "redirects to the created jukebox" do
        post :create, params: { jukebox: jukebox_params }
        expect(response).to redirect_to(assigns(:jukebox))
      end
    end

    context "with invalid params" do
      it "does not create a new jukebox" do
        expect {
          post :create, params: { jukebox: { name: nil } }
        }.not_to change(Jukebox, :count)
      end

      it "renders the 'new' template" do
        post :create, params: { jukebox: { name: nil } }
        expect(response).to redirect_to(action: :new)
      end
    end
  end

  describe "GET #show" do
    context "when the jukebox belongs to the current user" do
      let(:playlist_uid) { "12345" }
      let(:playlist) { create(:playlist, playlist_uid:, user:) }
      let(:jukebox) { create(:jukebox, user:, playlist:) }
      let(:limit) { 100 }
      let(:offset) { 0 }

      it "assigns the necessary instance variables" do
        stub_fetch_song(playlist_uid:, limit:, offset:)
        stub_fetch_currently_playing_and_queue
        get :show, params: { id: jukebox.id }
        expect(assigns(:jukebox)).to eq(jukebox)
        expect(assigns(:songs_per_page)).to be_a(Array)
        expect(response).to render_template(layout: "application-jukebox")
      end

      context "when song is playing" do
        it "assigns the currently playing song and the queue" do
          stub_fetch_currently_playing_and_queue
          stub_fetch_song(playlist_uid:, limit:, offset:)
          get :show, params: { id: jukebox.id }
          expect(assigns(:currently_playing_song)).to eq({name: "Song Name - Artist Name", cover_uri: "https://example.com/cover.jpg", uri: "spotify:track:123456"})
        end
      end

      context "when song is not playing" do
        it "assigns the currently playing song and the queue with default values" do
          stub_fetch_currently_playing_and_queue(return_status: 404, with_body: false)
          stub_fetch_song(playlist_uid:, limit:, offset:)
          get :show, params: { id: jukebox.id }
          expect(assigns(:currently_playing_song)).to eq({name: "Waiting for first Song", cover_uri: "", uri: ""})
          expect(assigns(:queue)).to eq([])
        end
      end


      context "when jukebox has more than 240 songs" do
        let(:jukebox) { create(:jukebox, user:, playlist:) }
        let!(:songs) { create_list(:song, 241, jukebox:) }
        it "assigns the first 240 songs to @songs" do
          stub_fetch_currently_playing_and_queue
          stub_fetch_song(playlist_uid:, limit:, offset:)
          get :show, params: { id: jukebox.id }
          expect(assigns(:songs)).to eq(jukebox.songs.limit(240).order(:artist, :name))
        end
      end

      context "when jukebox has a name" do
        let(:jukebox) { create(:jukebox, user:, playlist:, name: "Jukebox Name") }
        it "assigns the jukebox name to the jukebox title" do
          stub_fetch_currently_playing_and_queue
          stub_fetch_song(playlist_uid:, limit:, offset:)
          get :show, params: { id: jukebox.id }
          expect(assigns(:jukebox_title)).to eq("Jukebox Name")
        end
      end

      context "when jukebox does not have a name" do
        let(:jukebox) { create(:jukebox, user:, playlist:, name: nil) }
        it "assigns 'Music' to the jukebox title" do
          stub_fetch_currently_playing_and_queue
          stub_fetch_song(playlist_uid:, limit:, offset:)
          get :show, params: { id: jukebox.id }
          expect(assigns(:jukebox_title)).to eq("Music")
        end
      end
    end

    context "when the jukebox does not belong to the current user" do
      it "redirects to the 'new' action" do
        get :show, params: { id: 9999 }
        expect(flash[:notice]).to eq("Jukebox nicht gefunden. Bitte probieren Sie es erneut.")
        expect(response).to redirect_to(action: :new)
      end
    end
  end

  describe "DELETE #destroy" do
    context "when the jukebox belongs to the current user" do
      it "destroys the jukebox" do
        delete :destroy, params: { id: jukebox.id }
        expect(flash[:notice]).to eq("Jukebox gelöscht.")
        expect(response).to redirect_to(root_path)
      end
    end

    context "when the jukebox does not belong to the current user" do
      it "does not destroy the jukebox" do
        delete :destroy, params: { id: 9999 }
        expect(flash[:notice]).to eq("Jukebox nicht gefunden. Bitte probieren Sie es erneut.")
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST #credits" do
    context "when the operation is 'add'" do
      it "increases the jukebox credit" do
        post :credits, params: { jukebox_id: jukebox.id, operation: "add" }
        jukebox.reload
        expect(jukebox.credit).to eq(1)
      end

      it "renders the updated credit as JSON" do
        post :credits, params: { jukebox_id: jukebox.id, operation: "add" }
        expect(response.body).to eq({ new_credit: 1 }.to_json)
      end
    end

    context "when the operation is 'remove'" do
      before { jukebox.update(credit: 2) }

      it "decreases the jukebox credit" do
        post :credits, params: { jukebox_id: jukebox.id, operation: "remove" }
        jukebox.reload
        expect(jukebox.credit).to eq(1)
      end

      it "renders the updated credit as JSON" do
        post :credits, params: { jukebox_id: jukebox.id, operation: "remove" }
        expect(response.body).to eq({ new_credit: 1 }.to_json)
      end
    end
  end

  describe "POST #add_song" do
    context "when the song is not already playing or in the queue" do
      before do
        allow(SpotifyConnector).to receive(:add_song_to_queue)
        allow(controller).to receive(:render)
      end

      it "adds the song to the jukebox's queue" do
        expect(SpotifyConnector).to receive(:add_song_to_queue).with(jukebox, song)
        post :add_song, params: { jukebox_id: jukebox.id, song_id: song.id }
      end

      it "renders the updated queued songs and credits as JSON" do
        expected_response = [ { credits: { amount: jukebox.credit } }]
        expect(controller).to receive(:render).with(json: expected_response.to_json)
        post :add_song, params: { jukebox_id: jukebox.id, song_id: song.id }
      end
    end
  end

  describe "GET #playing_song" do
    skip "TODO: Implement after queue is implemented" do
      let!(:jukebox_song) { create(:song, uri: "spotify:track:123456", name: "Song Name - Artist Name", cover_uri: "https://example.com/cover.jpg", jukebox:) }

      context "when the jukebox song is found and not already playing" do
        it "updates the currently playing song and the queue" do
          stub_fetch_currently_playing_and_queue(return_status: 200, with_body: true)
          song_info = SpotifyConnector.add_song_to_queue(user)
          get :playing_song, params: { jukebox_id: jukebox.id }

          expect(response.body).to eq({ currently_playing_song: song_info, queue_update: false }.to_json)
        end
      end

      context "when the jukebox song is not found or already playing" do
        it "does not update the currently playing song and the queue" do
          stub_fetch_currently_playing_and_queue
          get :playing_song, params: { jukebox_id: jukebox.id }
          expect(response.body).to eq({ currently_playing_song: nil, queue_update: false }.to_json)
        end
      end
    end
  end

  describe "POST #next_song" do
    it "plays the next song" do
      expect(controller).to receive(:play_next_song).with(jukebox.user)
      post :next_song, params: { jukebox_id: jukebox.id }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST #take_photo" do
    let(:image_data) { "base64image" }
    let(:decoded_image) { "decoded_image" }

    before do
      allow(controller).to receive(:head)
      allow(Base64).to receive(:decode64).with(image_data).and_return(decoded_image)
      allow(jukebox.images).to receive(:attach)
    end

    it "returns a success status" do
      post :take_photo, params: { jukebox_id: jukebox.id, song_id: song.id, image: image_data }
      expect(response).to have_http_status(:ok)
    end
  end
end
