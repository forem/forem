# Register the built-in tracking adapters. Contributors can register their own
# adapters from a separate initializer; selection is via the comma-separated
# TRACKABLE_ADAPTERS env var. Wrapped in to_prepare so registrations survive
# Zeitwerk reloads in development.
Rails.application.reloader.to_prepare do
  Trackable::Registry.register(:null, Trackers::Null)
  Trackable::Registry.register(:customerio_cdp, Trackers::CustomerioCdp)
end

# A dispatch job finishes once its calls are queued in the adapter's memory, so
# a process stopping for a deploy would otherwise drop events Sidekiq already
# counts as delivered.
at_exit { Trackable::Registry.flush }
