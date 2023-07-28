Rails.application.config.to_prepare do
  # Explicitly load extensions on the `countries` gem so they are always available
  Rails.root.glob("lib/ISO3166/*.rb").each do |filename|
    require_dependency filename
  end
end
