Rails.application.reloader.to_prepare do
  Rails.root.glob("app/lib/reverse_markdown/converters/*.rb").each do |filename|
    require_dependency filename
  end
end
