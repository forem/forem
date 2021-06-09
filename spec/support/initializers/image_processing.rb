RSpec.configure do |config|
  config.before(:each, cloudinary: true) do |_example|
    allow(Cloudinary.config).to receive(:cloud_name).and_return("CLOUD_NAME")
    allow(Cloudinary.config).to receive(:api_key).and_return("API_KEY")
    allow(Cloudinary.config).to receive(:api_secret).and_return("API_SECRET")
    allow(Cloudinary.config).to receive(:secure).and_return("SECURE")
  end
end
