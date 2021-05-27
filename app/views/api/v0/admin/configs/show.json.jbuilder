@settings.each do |config|
  json.set! config.var, config.value
end
