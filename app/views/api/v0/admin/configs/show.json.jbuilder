@settings_general.each do |config|
  json.set! config.var, config.value
end
