class UsersController < ApplicationController
  def show
    @jukeboxes = Jukebox.where(user: current_user).order(created_at: :desc).with_attached_images
  end

  def download
    jukebox = Jukebox.find(params[:jukebox_id])
    temp_images = save_files_on_server(jukebox.images)
    zip_data = create_temporary_zip_file(temp_images)

    send_data(zip_data, type: 'application/zip', filename: 'jukebox-images.zip')
  end

  private

  def save_files_on_server(images)
    temp_folder = File.join(Dir.tmpdir, "user_#{current_user.id}-jukebox")
    FileUtils.mkdir_p(temp_folder) unless Dir.exist?(temp_folder)
    images.map do |img|
      filename = "#{img.created_at.strftime("%Y-%m-%d-%H-%M")} - #{img.filename.to_s}"

      filepath = File.join(temp_folder, filename)
      File.open(filepath, 'wb') do |f|
        img.download { |chunk| f.write(chunk) }
      end
      filepath
    end
  end

  def create_temporary_zip_file(filepaths)
    # require 'zip'
    temp_file = Tempfile.new('jukebox-images.zip')
    begin
      # Initialize the temp file as a zip file
      Zip::OutputStream.open(temp_file) { |zos| }
      Zip::File.open(temp_file.path, Zip::File::CREATE) do |zip|
        filepaths.each_with_index do |filepath|
          filename = File.basename(filepath)
          # add file into the zip
          zip.add(filename, filepath)
        end
      end
      File.read(temp_file.path)
    ensure
      # close all ressources & remove temporary files
      temp_file.close
      temp_file.unlink
      filepaths.each { |filepath| FileUtils.rm(filepath) }
    end
  end
end