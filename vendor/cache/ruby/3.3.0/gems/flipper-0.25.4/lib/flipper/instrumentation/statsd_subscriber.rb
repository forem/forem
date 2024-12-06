# Note: You should never need to require this file directly if you are using
# ActiveSupport::Notifications. Instead, you should require the statsd file
# that lives in the same directory as this file. The benefit is that it
# subscribes to the correct events and does everything for your.
require 'flipper/instrumentation/subscriber'

module Flipper
  module Instrumentation
    class StatsdSubscriber < Subscriber
      class << self
        attr_accessor :client
      end

      def update_timer(metric)
        if self.class.client
          self.class.client.timing metric, (@duration * 1_000).round
        end
      end

      def update_counter(metric)
        self.class.client.increment metric if self.class.client
      end
    end
  end
end
