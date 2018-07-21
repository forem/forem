Cloudinary.config do |config|
  config.cloud_name = ApplicationConfig["CLOUDINARY_CLOUD_NAME"]
  config.api_key = ApplicationConfig["CLOUDINARY_API_KEY"]
  config.api_secret = ApplicationConfig["CLOUDINARY_API_SECRET"]
  config.secure = ApplicationConfig["CLOUDINARY_SECURE"]
end
