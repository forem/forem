require 'libhoney'

key = ApplicationConfig["HONEYCOMB_API_KEY"]
dataset = "dev.to-#{Rails.env}"

$libhoney = Libhoney::Client.new(:writekey => key, :dataset => dataset)

HoneycombRails.configure do |conf|
  conf.writekey = key
  conf.dataset = dataset
  conf.db_dataset = "dev.to-db-#{Rails.env}"
  conf.client = $libhoney
end
