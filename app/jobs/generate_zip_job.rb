require "zip"

class GenerateZipJob < ApplicationJob
  queue_as :default

  def perform(jukebox_name, jukebox_id)
    @jukebox_name = jukebox_name
    @images = Jukebox.find(jukebox_id).images
    temp_images = save_files_on_server
    zip_data = create_temporary_zip_file(temp_images)
  end

  def save_files_on_server
    temp_folder = "#{zip_directory}#{@jukebox_name}"
    FileUtils.mkdir_p(temp_folder) unless Dir.exist?(temp_folder)
    @images.map do |img|
      filename = "#{img.created_at.strftime('%Y-%m-%d-%H-%M')} - #{img.filename}"

      filepath = File.join(temp_folder, filename)
      File.open(filepath, 'wb') do |f|
        img.download { |chunk| f.write(chunk) }
      end
      filepath
    end
  end

  def create_temporary_zip_file(temp_images)
    begin
      file_name = "#{zip_directory}#{@jukebox_name}.zip"
      FileUtils.rm(file_name) if File.exist?(file_name)
      Zip::File.open(file_name, Zip::File::CREATE) do |zipfile|
        temp_images.each do |filepath|
          filename = File.basename(filepath)
          zipfile.add(filename, filepath)
        end
      end
    ensure
      temp_images.each { |filepath| FileUtils.rm(filepath) }
      FileUtils.rm_rf("#{zip_directory}#{@jukebox_name}") if Dir.exist?("#{zip_directory}#{@jukebox_name}")
    end
  end

  def zip_directory
    "#{Rails.root}/tmp/zip/"
  end
end
