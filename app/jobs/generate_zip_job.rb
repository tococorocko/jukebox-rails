require "zip"

class GenerateZipJob < ApplicationJob
  queue_as :default

  def perform(jukebox_name, jukebox_id)
    logger.info "1. Processing the job with name: #{jukebox_name} and id: #{jukebox_id}"
    @jukebox_name = jukebox_name
    @images = Jukebox.find(jukebox_id).images
    temp_images = save_files_on_server
    zip_data = create_temporary_zip_file(temp_images)
  end

  def save_files_on_server
    temp_folder = "#{zip_directory}#{@jukebox_name}"
    FileUtils.mkdir_p(temp_folder) unless Dir.exist?(temp_folder)
    logger.info "2. Save Files on Server with temp_folder: #{@jukebox_name} and #{@images.count} images."
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
      logger.info "3. Create Temporary Zip File with #{file_name} and i.e. #{temp_images.first}."
      FileUtils.rm(file_name) if File.exist?(file_name)
      Zip::File.open(file_name, Zip::File::CREATE) do |zipfile|
        temp_images.each do |filepath|
          filename = File.basename(filepath)
          zipfile.add(filename, filepath)
        end
      end
      logger.info "4. Done! file_name #{file_name} exists? #{File.exist?(file_name)}}"
    ensure
      # temp_images.each { |filepath| FileUtils.rm(filepath) }
      # FileUtils.rm_rf("#{zip_directory}#{@jukebox_name}") if Dir.exist?("#{zip_directory}#{@jukebox_name}")
    end
  end

  def zip_directory
    "#{Rails.root}/tmp/zip/"
  end
end
