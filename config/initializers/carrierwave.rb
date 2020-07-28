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
  elsif Rails.env.development? || ENV["FILE_STORAGE_LOCATION"] == "file"
    config.storage = :file
  else
    # region = ApplicationConfig["AWS_UPLOAD_REGION"].presence || ApplicationConfig["AWS_DEFAULT_REGION"]
    config.fog_provider = "fog/aws"
    config.fog_credentials = if ENV["HEROKU_APP_ID"].present? # Present if Heroku meta info is present.
                               {
                                 provider: "AWS",
                                 aws_access_key_id: ApplicationConfig["AWS_ID"],
                                 aws_secret_access_key: ApplicationConfig["AWS_SECRET"],
                                 region: "us-east-2"
                               }
                             else # jdoss's special sauce
                               {
                                 provider: "AWS",
                                 aws_access_key_id: ApplicationConfig["AWS_ID"],
                                 aws_secret_access_key: ApplicationConfig["AWS_SECRET"],
                                 use_iam_profile: true,
                                 region: "us-east-2"
                               }
                             end
    config.asset_host = "https://#{ApplicationConfig['APP_DOMAIN']}/images"
    config.fog_directory = "forem-12345-uploads"
    config.fog_public    = false
    config.storage = :fog
  end
end
