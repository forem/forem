require 'carrierwave/storage/abstract'
require 'carrierwave/storage/file'
require 'carrierwave/storage/fog'

CarrierWave.configure do |config|

  if Rails.env.development? || Rails.env.test?
    config.storage = :file
  else
    # config.fog_provider = 'fog-aws'
    config.storage = :fog
    config.fog_credentials = {
      :provider               => 'AWS',
      :aws_access_key_id      =>  ENV['AWS_ID'],
      :aws_secret_access_key  => ENV['AWS_SECRET'],
      :region                 => 'us-east-1'
    }
    config.fog_directory = ENV['AWS_BUCKET_NAME']
  end
end
