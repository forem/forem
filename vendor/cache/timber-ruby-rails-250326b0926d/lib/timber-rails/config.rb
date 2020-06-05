require 'timber/config'
require 'timber-rack/config'
require 'timber-rails/config/action_view'
require 'timber-rails/config/active_record'
require 'timber-rails/config/action_controller'

Timber::Config.instance.define_singleton_method(:logrageify!) do
  integrations.action_controller.silence = true
  integrations.action_view.silence = true
  integrations.active_record.silence = true
  integrations.rack.http_events.collapse_into_single_event = true
end
