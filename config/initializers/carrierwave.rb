CarrierWave.configure do |config|
  if Rails.env.test?
    config.storage = :file
    config.enable_processing = false
  elsif Rails.env.development?
    config.storage = :file
  else
    config.fog_provider = "fog/aws"
    if ENV["USE_NEW_AWS"]
      config.fog_credentials = {
        provider: "AWS",
        aws_access_key_id: ApplicationConfig["AWS_UPLOAD_ID"],
        aws_secret_access_key: ApplicationConfig["AWS_UPLOAD_SECRET"],
        region: ApplicationConfig["AWS_UPLOAD_REGION"]
      }
      config.fog_directory = ApplicationConfig["AWS_UPLOAD_BUCKET_NAME"]
    else
      config.fog_credentials = {
        provider: "AWS",
        aws_access_key_id: ApplicationConfig["AWS_ID"],
        aws_secret_access_key: ApplicationConfig["AWS_SECRET"],
        region: ApplicationConfig["AWS_DEFAULT_REGION"]
      }
      config.fog_directory = ApplicationConfig["AWS_BUCKET_NAME"]
    end
    config.storage = :fog
  end
end
