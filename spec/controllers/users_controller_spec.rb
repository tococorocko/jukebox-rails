require "rails_helper"

RSpec.describe UsersController, type: :controller do
  before do
    sign_in(user)
  end

  describe "GET #show" do
    let(:user) { create(:user) }
    let(:with_attachment) { true }

    it "assigns jukeboxes ordered by created_at with attached images" do
      jukebox1 = create(:jukebox, user: user, with_attachment: with_attachment)
      jukebox2 = create(:jukebox, user: user, with_attachment: with_attachment)
      get :show
      expect(assigns(:jukeboxes)).to eq([jukebox2, jukebox1])
    end

    context "when jukebox has attached images" do
      it "keeps jukeboxes" do
        jukebox = create(:jukebox, user: user, with_attachment: with_attachment)
        get :show
        expect(Jukebox.find_by(id: jukebox.id)).to be_present
      end
    end

    context "when jukebox has not attached images" do
      let(:with_attachment) { false }
      it "destroys jukebox" do
        jukebox = create(:jukebox, user: user, with_attachment: with_attachment)
        get :show
        expect(Jukebox.find_by(id: jukebox.id)).to be_nil
      end
    end
  end

  describe "GET #gallery" do
    let(:user) { create(:user) }
    let(:jukebox) { create(:jukebox, user: user, with_attachment: true) }

    context "when jukebox is found" do
      it "assigns shuffled images" do
        get :gallery, params: { jukebox_id: jukebox.id }
        expect(assigns(:images)).to match_array(jukebox.images)
      end
    end

    context "when jukebox is not found" do
      it "sets a flash notice and redirects to #show" do
        get :gallery, params: { jukebox_id: 999 }
        expect(flash[:notice]).to eq("Galerie nicht gefunden. Bitte probieren Sie es erneut.")
        expect(response).to redirect_to(action: :show)
      end
    end
  end

  describe "GET #download" do
    let(:user) { create(:user) }
    let(:jukebox) { create(:jukebox, user: user) }
    let(:file_name) { "user_#{user.id}-jukebox_#{jukebox.id}" }
    let(:file_path) { "#{User::ZIP_DIRECTORY}/#{file_name}.zip" }
    let(:last_modified_in_min) {}
    let(:aws_zip_file) { double("AwsZipFile", last_modified: last_modified_in_min) }

    context "when jukebox is found and zip file exists" do
      before do
        s3_bucket = instance_double(AwsBucket)
        allow(AwsBucket).to receive(:new).and_return(s3_bucket)
        allow(s3_bucket).to receive(:get).with(file_name, file_path).and_return(aws_zip_file)
        allow(File).to receive(:read).with(file_path).and_return("zip file content")
      end

      context "when zip file is not older than 10 minutes" do
        let(:last_modified_in_min) { 5.minutes.ago }
        it "sends the zip file" do
          get :download, params: { jukebox_id: jukebox.id }
          expect(response.headers["Content-Type"]).to eq("application/zip")
          expect(response.headers["Content-Disposition"]).to eq("attachment; filename=\"#{file_name}.zip\"; filename*=UTF-8''#{file_name}.zip")
          expect(response.body).to eq("zip file content")
        end
      end

      context "when zip file is older than 10 minutes" do
        let(:last_modified_in_min) { 11.minutes.ago }
        it "redirects to root path and enqueues GenerateZipJob" do
          get :download, params: { jukebox_id: jukebox.id }
          expect(flash[:notice]).to eq("Zip-Datei wird erstellt, laden Sie die Seite in ein paar Minuten neu und klicken Sie erneut auf Download.")
        end
      end
    end

    context "when jukebox is found and zip file needs regeneration" do
      before do
        s3_bucket = instance_double(AwsBucket)
        allow(AwsBucket).to receive(:new).and_return(s3_bucket)
        allow(s3_bucket).to receive(:get).with(file_name, file_path).and_return(nil)
      end

      it "redirects to root path and enqueues GenerateZipJob" do
        expect {
          get :download, params: { jukebox_id: jukebox.id }
        }.to have_enqueued_job(GenerateZipJob).with(file_name, file_path, jukebox.id)
        expect(flash[:notice]).to eq("Zip-Datei wird erstellt, laden Sie die Seite in ein paar Minuten neu und klicken Sie erneut auf Download.")
        expect(response).to redirect_to(root_path)
      end
    end

    context "when jukebox is not found" do
      it "sets a flash notice and redirects to #show" do
        get :download, params: { jukebox_id: 999 }
        expect(flash[:notice]).to eq("Jukebox nicht gefunden. Bitte probieren Sie es erneut.")
        expect(response).to redirect_to(action: :show)
      end
    end
  end
end
