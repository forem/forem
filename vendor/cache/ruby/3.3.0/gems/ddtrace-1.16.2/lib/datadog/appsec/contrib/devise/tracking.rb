# frozen_string_literal: true

require_relative '../../../kit/identity'

module Datadog
  module AppSec
    module Contrib
      module Devise
        # Internal module to track user events
        module Tracking
          LOGIN_SUCCESS_EVENT = 'users.login.success'
          LOGIN_FAILURE_EVENT = 'users.login.failure'
          SIGNUP_EVENT = 'users.signup'

          def self.track_login_success(trace, span, user_id:, **others)
            track(LOGIN_SUCCESS_EVENT, trace, span, **others)

            Kit::Identity.set_user(trace, span, id: user_id.to_s, **others) if user_id
          end

          def self.track_login_failure(trace, span, user_id:, user_exists:, **others)
            track(LOGIN_FAILURE_EVENT, trace, span, **others)

            span.set_tag('appsec.events.users.login.failure.usr.id', user_id) if user_id
            span.set_tag('appsec.events.users.login.failure.usr.exists', user_exists)
          end

          def self.track_signup(trace, span, user_id:, **others)
            track(SIGNUP_EVENT, trace, span, **others)
            Kit::Identity.set_user(trace, id: user_id.to_s, **others) if user_id
          end

          def self.track(event, trace, span, **others)
            span.set_tag("appsec.events.#{event}.track", 'true')
            span.set_tag("_dd.appsec.events.#{event}.auto.mode", Datadog.configuration.appsec.track_user_events.mode)

            others.each do |k, v|
              raise ArgumentError, 'key cannot be :track' if k.to_sym == :track

              span.set_tag("appsec.events.#{event}.#{k}", v) unless v.nil?
            end

            trace.keep!
          end
        end
      end
    end
  end
end
