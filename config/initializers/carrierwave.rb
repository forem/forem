require "mini_magick"

# Carrierwave uses MiniMagick for image processing. To prevent server timeouts
# we are setting the MiniMagick timeout lower.
MiniMagick.configure do |config|
  config.timeout = 10
end

if Rails.env.production? && ApplicationConfig["AWS_BUCKET_NAME"] && ENV["FILE_STORAGE_LOCATION"] != "file"
  CarrierWave.configure do |config|
    config.storage = :fog
    config.fog_directory = ApplicationConfig["AWS_BUCKET_NAME"]
    config.fog_provider = "fog/aws"
    if ENV["FOREM_CONTEXT"] == "forem_cloud" # @forem/systems jdoss's special sauce.
      config.asset_host = "https://#{ApplicationConfig['APP_DOMAIN']}/remoteimages"
      config.fog_public = false
      config.fog_credentials = {
        provider: "AWS",
        use_iam_profile: true,
        region: "us-east-2"
      }
    else
      config.fog_attributes = { cache_control: "public, max-age=#{365.days.to_i}" }
      config.fog_credentials = {
        provider: "AWS",
        aws_access_key_id: ApplicationConfig["AWS_ID"],
        aws_secret_access_key: ApplicationConfig["AWS_SECRET"],
        region: ApplicationConfig["AWS_UPLOAD_REGION"].presence || ApplicationConfig["AWS_DEFAULT_REGION"]
      }
    end
  end
else
  CarrierWave.configure do |config|
    config.storage = :file
    config.enable_processing = !Rails.env.test?
    config.asset_host = if Rails.env.production?
                          "https://#{ApplicationConfig['APP_DOMAIN']}/localimages"
                        elsif Images::Optimizer.imgproxy_enabled?
                          "http://#{ApplicationConfig['APP_DOMAIN']}"
                        end
  end
end
