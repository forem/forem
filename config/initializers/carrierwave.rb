CarrierWave.configure do |config|
  if Rails.env.development? || Rails.env.test?
    config.storage = :file
    config.enable_processing = false
  else
    config.fog_provider = "fog/aws"
    config.fog_credentials = {
      provider: "AWS",
      aws_access_key_id: ApplicationConfig["AWS_ID"],
      aws_secret_access_key: ApplicationConfig["AWS_SECRET"],
      region: "us-east-1"
    }
    config.fog_directory = ApplicationConfig["AWS_BUCKET_NAME"]
    config.storage = :fog
  end
end
