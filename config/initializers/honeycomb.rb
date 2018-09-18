HoneycombRails.configure do |conf|
  conf.writekey = ApplicationConfig["HONEYCOMB_API_KEY"]
  conf.dataset = "dev.to-#{Rails.env}"
  conf.db_dataset = "dev.to-db-#{Rails.env}"
end
