# TODO: [rhymes] [Rails 6] explicitly requiring dependencies in `classic` mode.
# Will move over to `zeitwerk` in a future PR
Dir.glob(Rails.root.join("lib/liquid/*.rb")).sort.each do |filename|
  require_dependency filename
end

# Our custom Liquid tags are registered to Liquid::Template at the bottom of
# each files. Each Liquid tags will need to be loaded/required before the main
# Liquid gem is evoked, hence the need for the fix below.

Rails.application.config.to_prepare do
  Dir.glob(Rails.root.join("app/liquid_tags/*.rb")).sort.each do |filename|
    require_dependency filename
  end
end
