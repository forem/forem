require "mini_magick"

# Carrierwave uses MiniMagick for image processing. To prevent server timeouts
# we are setting the MiniMagick timeout lower.
MiniMagick.configure do |config|
  config.timeout = 10
end

# rubocop:disable Metrics/BlockLength
CarrierWave.configure do |config|
  if Rails.env.test?
    config.storage = :file
    config.enable_processing = false
  elsif Rails.env.development?
    # config.asset_host = "https://#{ApplicationConfig['APP_DOMAIN']}"
    config.storage = :file
  elsif ENV["FILE_STORAGE_LOCATION"] == "file" # @forem/systems production version of file store
    config.asset_host = "https://#{ApplicationConfig['APP_DOMAIN']}/images"
    config.storage = :file
  else
    config.fog_provider = "fog/aws"
    if ENV["FOREM_CONTEXT"] == "forem_cloud" # @forem/systems jdoss's special sauce.
      config.fog_credentials = {
        provider: "AWS",
        use_iam_profile: true,
        region: "us-east-2"
      }
      config.asset_host = "https://#{ApplicationConfig['APP_DOMAIN']}/images"
      config.fog_public = false
    elsif ApplicationConfig["AWS_ID"].present?
      region = ApplicationConfig["AWS_UPLOAD_REGION"].presence || ApplicationConfig["AWS_DEFAULT_REGION"]
      config.fog_credentials = {
        provider: "AWS",
        aws_access_key_id: ApplicationConfig["AWS_ID"],
        aws_secret_access_key: ApplicationConfig["AWS_SECRET"],
        region: region
      }
    else
      # Fallback on file storage if AWS creds are not present
      config.asset_host = "https://#{ApplicationConfig['APP_DOMAIN']}/images"
      config.storage = :file
    end
    config.fog_directory = ApplicationConfig["AWS_BUCKET_NAME"]
    config.storage = :fog
  end
end
# rubocop:enable Metrics/BlockLength
