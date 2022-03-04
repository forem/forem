Rails.application.config.to_prepare do
  # Explicitly requiring lib/liquid to make sure that our patches are loaded
  # before liquid tags are loaded
  Dir.glob(Rails.root.join("lib/liquid/*.rb")).each do |filename|
    require_dependency filename
  end

  # Our custom Liquid tags are registered to Liquid::Template at the bottom of
  # each files. Each Liquid tags will need to be loaded/required before the main
  # Liquid gem is evoked, hence the need to pre-require them in order
  Dir.glob(Rails.root.join("app/liquid_tags/*.rb")).each do |filename|
    require_dependency filename
  end
end
