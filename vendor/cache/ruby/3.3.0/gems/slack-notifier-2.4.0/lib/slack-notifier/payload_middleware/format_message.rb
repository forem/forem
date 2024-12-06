# frozen_string_literal: true

module Slack
  class Notifier
    class PayloadMiddleware
      class FormatMessage < Base
        middleware_name :format_message

        options formats: %i[html markdown]

        def call payload={}
          return payload unless payload[:text]
          payload[:text] = Util::LinkFormatter.format(payload[:text], options)

          payload
        end
      end
    end
  end
end
