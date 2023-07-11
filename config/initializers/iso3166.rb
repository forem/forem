Rails.application.config.to_prepare do
  Rails.root.glob("lib/iso3166/*.rb").each do |filename|
    require_dependency filename
  end
end
