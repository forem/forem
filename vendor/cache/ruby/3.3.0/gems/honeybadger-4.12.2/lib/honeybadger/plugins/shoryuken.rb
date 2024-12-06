require 'honeybadger/plugin'
require 'honeybadger/ruby'

module Honeybadger
  module Plugins
    module Shoryuken
      class Middleware
        def call(_worker, _queue, sqs_msg, body)
          begin
            yield
          rescue => e
            if attempt_threshold <= receive_count(sqs_msg)
              Honeybadger.notify(e, parameters: notification_params(body))
            end

            raise e
          end
        ensure
          Honeybadger.clear!
        end

        private

        def attempt_threshold
          ::Honeybadger.config[:'shoryuken.attempt_threshold'].to_i
        end

        def receive_count(sqs_msg)
          return 0 if sqs_msg.is_a?(Array)

          sqs_msg.attributes['ApproximateReceiveCount'.freeze].to_i
        end

        def notification_params(body)
          body.is_a?(Array) ? { batch: body } : { body: body }
        end
      end

      Plugin.register do
        requirement { defined?(::Shoryuken) }

        execution do
          ::Shoryuken.configure_server do |config|
            config.server_middleware do |chain|
              chain.add Middleware
            end
          end
        end
      end
    end
  end
end
