require 'rails_helper'

RSpec.describe "Users", type: :request do
  describe "GET root_path" do
    let(:user) { create(:user) }
    context "when user is signed in" do
      before { sign_in(user) }
      it "renders the show template" do
        expect(get(root_path)).to render_template(:show)
      end
    end

    context "when user is not signed in" do
      it "redirects to the sign in page" do
        expect(get(root_path)).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET users#show" do
    context "when user is not signed in" do
      it "redirects to the sign in page" do
        expect(get(root_path)).to redirect_to(new_user_session_path)
      end
    end

    context "when user is signed in" do
      before { sign_in(user) }
      let(:user) { create(:user) }
      it "renders the show template" do
        get root_path
        expect(response).to render_template(:show)
      end
    end
  end

  describe "GET users#gallery" do
    context "when user is not signed in" do
      it "redirects to the sign in page" do
        expect(get(gallery_path(1))).to redirect_to(new_user_session_path)
      end
    end

    context "when user is signed in" do
      let(:user) { create(:user) }
      before { sign_in(user) }

      context "when jukebox is found" do
        let(:jukebox) { create(:jukebox, user: user, with_attachment: true) }
        it "renders the gallery template" do
          get gallery_path(jukebox)
          expect(response).to render_template(:gallery)
        end
      end

      context "when jukebox is not found" do
        it "redirects to #show" do
          expect(get(gallery_path(199))).to redirect_to(action: :show)
        end
      end
    end
  end

  describe "GET users#download" do
    context "when user is not signed in" do
      it "redirects to the sign in page" do
        expect(get(download_path(1))).to redirect_to(new_user_session_path)
      end
    end

    context "when user is signed in" do
      before { sign_in(user) }
      let(:user) { create(:user) }
      let(:jukebox) { create(:jukebox, user: user) }

      context "when jukebox is found" do
        let(:file_name) { "user_#{user.id}-jukebox_#{jukebox.id}" }
        let(:file_path) { "#{User::ZIP_DIRECTORY}/#{file_name}.zip" }
        let(:s3_bucket) { instance_double(AwsBucket) }
        let(:aws_zip_file) { double("AwsZipFile", last_modified: 5.minutes.ago) }
        before do
          allow(AwsBucket).to receive(:new).and_return(s3_bucket)
        end

        context "when zip file is found" do
          before do
            allow(s3_bucket).to receive(:get).with(file_name, file_path).and_return(aws_zip_file)
            allow(File).to receive(:read).with(file_path).and_return("zip file content")
          end
          it "sends the zip file" do
            get download_path(jukebox)
            expect(response.body).to eq("zip file content")
            expect(response.content_type).to eq("application/zip")
            expect(response.headers["Content-Disposition"]).to include("#{file_name}.zip")
          end
        end

        context "when zip file is not found" do
          before do
            allow(s3_bucket).to receive(:get).with(file_name, file_path).and_return(nil)
          end

          it "sets a flash notice, triggers background job and redirects to #show" do
            get download_path(jukebox)
            expect(flash[:notice]).to eq("Zip-Datei wird erstellt, laden Sie die Seite in ein paar Minuten neu und klicken Sie erneut auf Download.")
            expect(response).to redirect_to(root_path)
            expect(GenerateZipJob).to have_been_enqueued.with(file_name, file_path, jukebox.id)
          end
        end
      end

      context "when jukebox is not found" do
        let(:jukebox) {}
         it "redirects to #show" do
          expect(get(download_path(199))).to redirect_to(action: :show)
         end
      end
    end
  end
end
