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
    config.storage = :file
  else
    config.fog_provider = "fog/aws"
    config.storage = :fog
    region = ApplicationConfig["AWS_UPLOAD_REGION"].presence || ApplicationConfig["AWS_DEFAULT_REGION"]
    if ENV["HEROKU_APP_ID"].present?
      config.fog_credentials = {
        provider: "AWS",
        aws_access_key_id: ApplicationConfig["AWS_ID"],
        aws_secret_access_key: ApplicationConfig["AWS_SECRET"],
        region: region
      }
      config.fog_directory = ApplicationConfig["AWS_BUCKET_NAME"]
    else # @forem/systems Non-Heroku for our WIP container
      config.fog_credentials = {
        provider: "AWS",
        use_iam_profile: true,
        region: region
      }
      config.asset_host = "https://#{ApplicationConfig['APP_DOMAIN']}/images"
      config.fog_directory = "forem-12345-uploads"
      config.fog_public    = false
    end
  end
end
