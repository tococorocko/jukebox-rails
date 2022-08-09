class UsersController < ApplicationController
  def show
    @jukeboxes = Jukebox.where(user: current_user).order(created_at: :desc).with_attached_images
  end

  def gallery
    jukebox = Jukebox.find(params[:jukebox_id])
    @images = jukebox.images.shuffle
  end

  def download
    jukebox = Jukebox.find(params[:jukebox_id])
    file_name = file_name(current_user.id, jukebox.id)
    file_path = "#{zip_directory}#{file_name}.zip"
    if File.exist?(file_path)
      zip_data = File.read(file_path)
      send_data(zip_data, type: 'application/zip', filename: file_name)
    else
      flash[:notice] = 'Zip-Datei wird erstellt, laden Sie die Seite in Kürze neu und klicken Sie erneut auf Download.'
      GenerateZipJob.perform_later(file_name, jukebox.id)
      redirect_to root_path
    end
  end

  private

  def file_name(user_id, jukebox_id)
    "user_#{user_id}-jukebox_#{jukebox_id}"
  end

  def zip_directory
    "#{Rails.root}/tmp/zip/"
  end
end
