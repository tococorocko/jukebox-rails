require 'rails_helper'

RSpec.describe "Jukeboxes", type: :request do
  describe "GET jukeboxes#new" do
    let(:user) { create(:user) }
    context "when user is not signed in" do
      it "redirects to the sign in page" do
        expect(get(new_jukebox_path)).to redirect_to(new_user_session_path)
      end
    end

    context "when user is signed in" do
      before { sign_in(user) }
      it "renders the new template" do
        stub_device_request
        stub_playlist_request
        expect(get(new_jukebox_path)).to render_template(:new)
      end
    end
  end

  describe "POST jukeboxes#create" do
    let(:user) { create(:user) }
    context "when user is not signed in" do
      it "redirects to the sign in page" do
        expect(post(jukeboxes_path)).to redirect_to(new_user_session_path)
      end
    end
    context "when user is signed in" do
      before { sign_in(user) }
      let(:jukebox_params) { attributes_for(:jukebox).merge!(additional_params) }
      let(:additional_params) { {} }
      context "when params are invalid" do
        it "does not create a new jukebox" do
          post(jukeboxes_path, params: { jukebox: jukebox_params })
          expect(response).to redirect_to(action: :new)
          expect(flash[:notice]).to eq("Jukebox konnte nicht erstellt werden. Bitte probieren Sie es erneut. Fehler: User must exist, Device must exist, Playlist must exist")
        end
      end

      context "when params are valid" do
        let(:device) { create(:device, user: user) }
        let(:playlist) { create(:playlist, user: user) }
        let(:additional_params) { { user_id: user.id, device_id: device.id, playlist_id: playlist.id } }
        it "creates a new jukebox" do
          post(jukeboxes_path, params: { jukebox: jukebox_params })
          expect(response).to redirect_to(jukebox_path(assigns(:jukebox)))
        end
      end
    end
  end
end
