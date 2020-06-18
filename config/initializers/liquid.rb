Rails.application.config.to_prepare do
  # Explicitly requiring lib/liquid to make sure that our patches are loaded
  # before liquid tags are loaded
  Dir.glob(Rails.root.join("lib/liquid/*.rb")).sort.each do |filename|
    require_dependency filename
  end
end
