# frozen_string_literal: true

require_relative '../tracking'
require_relative '../resource'
require_relative '../event'

module Datadog
  module AppSec
    module Contrib
      module Devise
        module Patcher
          # Hook in devise registration controller
          module RegistrationControllerPatch
            def create
              return super unless AppSec.enabled?

              track_user_events_configuration = Datadog.configuration.appsec.track_user_events

              return super unless track_user_events_configuration.enabled

              automated_track_user_events_mode = track_user_events_configuration.mode

              appsec_scope = Datadog::AppSec.active_scope
              return super unless appsec_scope

              super do |resource|
                if resource.persisted?
                  devise_resource = Resource.new(resource)

                  event_information = Event.new(devise_resource, automated_track_user_events_mode)

                  if event_information.user_id
                    Datadog.logger.debug { 'User Signup Event' }
                  else
                    Datadog.logger.warn { 'User Signup Event, but can\'t extract user ID. Tracking empty event' }
                  end

                  Tracking.track_signup(
                    appsec_scope.trace,
                    appsec_scope.service_entry_span,
                    user_id: event_information.user_id,
                    **event_information.to_h
                  )
                end
              end
            end
          end
        end
      end
    end
  end
end
