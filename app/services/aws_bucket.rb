require 'aws-sdk-s3'

class AwsBucket

  def initialize
    env = Rails.env.production? ? :prod : :dev
    Aws.config.update({
                        region: Rails.application.credentials.aws[:region],
                        credentials:
                          Aws::Credentials.new(
                            Rails.application.credentials.aws[:access_key_id],
                            Rails.application.credentials.aws[:secret_access_key]
                          )
                      })
    @s3_bucket = Aws::S3::Resource.new.bucket(Rails.application.credentials.aws[env][:bucket])
  end

  def get(file_name, file_path)
    return @s3_bucket.object(file_name).get(response_target: file_path) if @s3_bucket.object(file_name).exists?
  end

  def upload(file_name, file_path)
    new_object = @s3_bucket.object(file_name)
    new_object.put(body: File.read(file_path))
  end
end