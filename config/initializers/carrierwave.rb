require "mini_magick"

# Carrierwave uses MiniMagick for image processing. To prevent server timeouts
# we are setting the MiniMagick timeout lower.
MiniMagick.configure do |config|
  config.timeout = 10
end

disk_storage = proc do |config|
  config.storage = :file
  config.enable_processing = !Rails.env.test?
  config.asset_host = if Rails.env.production?
                        "https://#{ApplicationConfig['APP_DOMAIN']}/localimages"
                      end
end

if !Rails.env.production? || ENV["FILE_STORAGE_LOCATION"] == "file"
  CarrierWave.configure(&disk_storage)
elsif ENV["FOREM_CONTEXT"] == "forem_cloud" # @forem/systems jdoss's special sauce.
  CarrierWave.configure do |config|
    config.storage = :fog
    config.asset_host = "https://#{ApplicationConfig['APP_DOMAIN']}/remoteimages"
    config.fog_directory = ApplicationConfig["AWS_BUCKET_NAME"]
    config.fog_provider = "fog/aws"
    config.fog_public = false
    config.fog_credentials = {
      provider: "AWS",
      use_iam_profile: true,
      region: "us-east-2"
    }
  end
elsif ApplicationConfig["AWS_ID"].present?
  CarrierWave.configure do |config|
    config.storage = :fog
    config.fog_provider = "fog/aws"
    config.fog_directory = ApplicationConfig["AWS_BUCKET_NAME"]
    config.fog_attributes = { cache_control: "public, max-age=#{365.days.to_i}" }
    config.fog_credentials = {
      provider: "AWS",
      aws_access_key_id: ApplicationConfig["AWS_ID"],
      aws_secret_access_key: ApplicationConfig["AWS_SECRET"],
      region: ApplicationConfig["AWS_UPLOAD_REGION"].presence || ApplicationConfig["AWS_DEFAULT_REGION"]
    }
  end
else # Fallback on file storage if AWS creds are not present
  CarrierWave.configure(&disk_storage)
end
