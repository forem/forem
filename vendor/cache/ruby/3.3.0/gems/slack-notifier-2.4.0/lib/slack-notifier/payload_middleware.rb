# frozen_string_literal: true

module Slack
  class Notifier
    class PayloadMiddleware
      class << self
        def registry
          @registry ||= {}
        end

        def register middleware, name
          registry[name] = middleware
        end
      end
    end
  end
end

require_relative "payload_middleware/stack"
require_relative "payload_middleware/base"
require_relative "payload_middleware/format_message"
require_relative "payload_middleware/format_attachments"
require_relative "payload_middleware/at"
require_relative "payload_middleware/channels"
