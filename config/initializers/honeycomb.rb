HoneycombRails.configure do |conf|
  conf.writekey = ApplicationConfig["HONEYCOMB_API_KEY"]
  conf.dataset = 'dev.to'
  conf.db_dataset = 'dev.to-db'
end
