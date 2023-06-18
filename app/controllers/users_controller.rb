class UsersController < ApplicationController
  def show
    jukeboxes = Jukebox.where(user: current_user)
    jukeboxes.each do |jukebox|
      jukebox.destroy unless jukebox.images.attached?
    end
    @jukeboxes = Jukebox.where(user: current_user).order(created_at: :desc).with_attached_images
  end

  def gallery
    jukebox = Jukebox.where(id: params[:jukebox_id], user: current_user).first
    if jukebox.present?
      @images = jukebox.images.shuffle
    else
      flash[:notice] = "Galerie nicht gefunden. Bitte probieren Sie es erneut."
      redirect_to action: :show
    end
  end

  def download
    jukebox = Jukebox.where(id: params[:jukebox_id], user: current_user).first
    if jukebox.present?

      @user_id = current_user.id
      @jukebox_id = jukebox.id
      @images = jukebox.images
      s3_bucket = AwsBucket.new
      aws_zip_file = s3_bucket.get(file_name, file_path)
      if aws_zip_file && aws_zip_file.last_modified > 10.minutes.ago
        aws_zip_file = File.read(file_path)
        send_data(aws_zip_file, type: "application/zip", filename: "#{file_name}.zip")
      else
        flash[:notice] =
          "Zip-Datei wird erstellt, laden Sie die Seite in ein paar Minuten neu und klicken Sie erneut auf Download."
        # BackgroundJob
        GenerateZipJob.perform_later(file_name, file_path, @jukebox_id)
        redirect_to root_path
      end
    else
      flash[:notice] = "Jukebox nicht gefunden. Bitte probieren Sie es erneut."
      redirect_to action: :show
    end
  end

  private

  def file_name
    "user_#{@user_id}-jukebox_#{@jukebox_id}"
  end

  def file_path
    "#{User::ZIP_DIRECTORY}/#{file_name}.zip"
  end
end
