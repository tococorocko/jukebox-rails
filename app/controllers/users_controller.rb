require "zip"

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
    if jukebox.blank?
      flash[:notice] = 'Gallerie nicht gefunden. Bitte probieren Sie es erneut.'
      redirect_to action: :show
    else
      @images = jukebox.images.shuffle
    end
  end

  def download
    jukebox = Jukebox.where(id: params[:jukebox_id], user: current_user).first
    if jukebox.blank?
      flash[:notice] = 'Jukebox nicht gefunden. Bitte probieren Sie es erneut.'
      redirect_to action: :show
    else
      @user_id = current_user.id
      @jukebox_id = jukebox.id
      @images = jukebox.images
      s3_bucket = AwsBucket.new
      aws_zip_file = s3_bucket.get(file_name, file_path)
      # regenerate zip file if older than 10 minutes
      if aws_zip_file && aws_zip_file.last_modified > 10.minutes.ago
        aws_zip_file = File.read(file_path)
        send_data(aws_zip_file, type: 'application/zip', filename: "#{file_name}.zip")
      else
        flash[:notice] = 'Zip-Datei wird erstellt, laden Sie die Seite in Kürze neu und klicken Sie erneut auf Download.'
        temp_images = download_images_to_tmp
        generate_zip(temp_images)
        s3_bucket.upload(file_name, file_path)
        #
        #
        # TODO:
        # GenerateZipJob.perform_later(file_name, file_path, @jukebox_id)
        #
        #
        redirect_to root_path
      end
    end
  end

  private

  def file_name
    "user_#{@user_id}-jukebox_#{@jukebox_id}"
  end

  def file_path
    "#{User::ZIP_DIRECTORY}/#{file_name}.zip"
  end

  def download_images_to_tmp
    temp_folder = "#{User::ZIP_DIRECTORY}/#{file_name}"
    FileUtils.mkdir_p(temp_folder) unless Dir.exist?(temp_folder)
    logger.info "2. Save Files on Server with temp_folder: #{temp_folder} and #{@images.count} images."
    @images.map do |img|
      filename = "#{img.created_at.strftime('%Y-%m-%d-%H-%M')} - #{img.filename}"
      filepath = File.join(temp_folder, filename)
      File.open(filepath, 'wb') do |f|
        img.download { |chunk| f.write(chunk) }
      end
      filepath
    end
  end

  def generate_zip(temp_images)
    begin
      logger.info "3. Create Temporary Zip File with #{file_path} and i.e. #{temp_images.first}."
      FileUtils.rm(file_path) if File.exist?(file_path)
      Zip::File.open(file_path, Zip::File::CREATE) do |zipfile|
        temp_images.each do |filepath|
          filename = File.basename(filepath)
          zipfile.add(filename, filepath)
        end
      end
      logger.info "4. Done! file_path #{file_path} exists? #{File.exist?(file_path)}}"
    ensure
      temp_images.each { |filepath| FileUtils.rm(filepath) }
      FileUtils.rm_rf("#{User::ZIP_DIRECTORY}/#{file_name}") if Dir.exist?("#{User::ZIP_DIRECTORY}/#{file_name}")
    end
  end
end
