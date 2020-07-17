require "mini_magick"

# Carrierwave uses MiniMagick for image processing. To prevent server timeouts
# we are setting the MiniMagick timeout lower.
MiniMagick.configure do |config|
  config.timeout = 10
end

CarrierWave.configure do |config|
  if Rails.env.test?
    config.storage = :file
    config.enable_processing = false
  elsif Rails.env.development?
    config.storage = :file
  else
    config.fog_provider = "fog/aws"
    config.fog_credentials = deployment_specific_credentials
    config.fog_directory = ApplicationConfig["AWS_BUCKET_NAME"]
    config.storage = :fog
  end
end

def deployment_specific_credentials
  region = ApplicationConfig["AWS_UPLOAD_REGION"].presence || ApplicationConfig["AWS_DEFAULT_REGION"]
  if ENV["HEROKU_APP_ID"].present? # Present if Heroku meta info is present.
    {
      provider: "AWS",
      aws_access_key_id: ApplicationConfig["AWS_ID"],
      aws_secret_access_key: ApplicationConfig["AWS_SECRET"],
      region: region
    }
  else # jdoss's special sauce
    {
      provider: "AWS",
      use_iam_profile: true,
      region: region
    }
  end
end
