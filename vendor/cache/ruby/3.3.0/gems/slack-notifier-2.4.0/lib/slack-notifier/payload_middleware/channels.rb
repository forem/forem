# frozen_string_literal: true

module Slack
  class Notifier
    class PayloadMiddleware
      class Channels < Base
        middleware_name :channels

        def call payload={}
          return payload unless payload[:channel].respond_to?(:to_ary)

          payload[:channel].to_ary.map do |channel|
            pld = payload.dup
            pld[:channel] = channel
            pld
          end
        end
      end
    end
  end
end
