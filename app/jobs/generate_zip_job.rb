require "zip"
class GenerateZipJob < ApplicationJob
  queue_as :default

  def perform(file_name, file_path, jukebox_id)
    logger.info "1. Processing the job with name: #{file_name} and id: #{jukebox_id}"
    @file_name = file_name
    @file_path = file_path
    @images = Jukebox.find(jukebox_id).images
    tmp_images = download_images_to_tmp
    generate_zip(tmp_images)
    AwsBucket.new.upload(file_name, file_path)
  end

  def download_images_to_tmp
    temp_folder = "#{User::ZIP_DIRECTORY}/#{@file_name}"
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
    logger.info "3. Create Temporary Zip File with #{@file_path} and i.e. #{temp_images.first}."
    FileUtils.rm(@file_path) if File.exist?(@file_path)
    Zip::File.open(@file_path, Zip::File::CREATE) do |zipfile|
      temp_images.each do |filepath|
        filename = File.basename(filepath)
        zipfile.add(filename, filepath)
      end
    end
    logger.info "4. Done! file_path #{@file_path} exists? #{File.exist?(@file_path)}}"
  ensure
    temp_images.each { |filepath| FileUtils.rm(filepath) }
    FileUtils.rm_rf("#{User::ZIP_DIRECTORY}/#{@file_name}") if Dir.exist?("#{User::ZIP_DIRECTORY}/#{@file_name}")
  end
end
