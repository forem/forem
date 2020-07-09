module Timber
  module Integrations
    module Rails
      # @private
      module ActiveSupportLogSubscriber
        extend self

        def find(component, type)
          ::ActiveSupport::LogSubscriber.log_subscribers.find do |subscriber|
            subscriber.class == type
          end
        end

        def subscribed?(component, type)
          !find(component, type).nil?
        end

        # I don't know why this has to be so complicated, but it is. This code was taken from
        # lograge :/
        def unsubscribe!(component, type)
          subscriber = find(component, type)

          if !subscriber
            raise "We could not find a log subscriber for #{component.inspect} of type #{type.inspect}"
          end

          events = subscriber.public_methods(false).reject { |method| method.to_s == 'call' }
          events.each do |event|
            ::ActiveSupport::Notifications.notifier.listeners_for("#{event}.#{component}").each do |listener|
              if listener.instance_variable_get('@delegate') == subscriber
                ::ActiveSupport::Notifications.unsubscribe listener
              end
            end
          end
        end
      end
    end
  end
end
