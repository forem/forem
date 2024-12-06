require 'honeybadger/plugin'
require 'honeybadger/util/lambda'

module Honeybadger
  module Plugins
    module LambdaExtension
      # Wrap Lambda handlers so exceptions can be automatically captured
      #
      # Usage:
      #
      # # Automatically included in the top-level main object
      # hb_wrap_handler :my_handler_1, :my_handler_2
      #
      # def my_handler_1(event:, context:)
      # end
      #
      # class MyLambdaApp
      #   extend ::Honeybadger::Plugins::LambdaExtension
      #
      #   hb_wrap_handler :my_handler_1, :my_handler_2
      #
      #   def self.my_handler_1(event:, context:)
      #   end
      # end
      def hb_wrap_handler(*handler_names)
        mod = Module.new do
          handler_names.each do |handler|
            define_method(handler) do |event:, context:|
              begin
                Honeybadger.context(aws_request_id: context.aws_request_id) if context.respond_to?(:aws_request_id)

                super(event: event, context: context)
              rescue => e
                Honeybadger.notify(e)
                raise
              end
            end
          end
        end

        self.singleton_class.prepend(mod)
        Kernel.singleton_class.prepend(mod) if self == TOPLEVEL_BINDING.eval("self")
      end
    end

    # @api private
    Plugin.register :lambda do
      requirement { Util::Lambda.lambda_execution? }

      execution do
        config[:sync] = true
        config[:'exceptions.notify_at_exit'] = false

        main = TOPLEVEL_BINDING.eval("self")
        main.extend(LambdaExtension)

        (config[:before_notify] ||= []) << lambda do |notice|
          data = Util::Lambda.normalized_data

          notice.component = data["function"]
          notice.action = data["handler"]
          notice.details["Lambda Details"] = data

          if (trace_id = Util::Lambda.trace_id)
            notice.context[:lambda_trace_id] = trace_id
          end
        end
      end
    end
  end
end
