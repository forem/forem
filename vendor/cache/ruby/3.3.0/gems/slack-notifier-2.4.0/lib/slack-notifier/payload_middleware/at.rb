# frozen_string_literal: true

module Slack
  class Notifier
    class PayloadMiddleware
      class At < Base
        middleware_name :at

        options at: []

        def call payload={}
          return payload unless payload[:at]

          payload[:text] = "#{format_ats(payload.delete(:at))}#{payload[:text]}"
          payload
        end

        private

          def format_ats ats
            Array(ats).map { |at| "<#{at_cmd_char(at)}#{at}> " }
                      .join("")
          end

          def at_cmd_char at
            case at
            when :here, :channel, :everyone, :group
              "!"
            else
              "@"
            end
          end
      end
    end
  end
end
