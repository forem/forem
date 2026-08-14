# Register the built-in tracking adapters. Contributors can register their own
# adapters from a separate initializer; selection is via the comma-separated
# TRACKABLE_ADAPTERS env var. Wrapped in to_prepare so registrations survive
# Zeitwerk reloads in development.
Rails.application.reloader.to_prepare do
  Trackable::Registry.register(:null, Trackers::Null)
  Trackable::Registry.register(:customerio_cdp, Trackers::CustomerioCdp)
end
