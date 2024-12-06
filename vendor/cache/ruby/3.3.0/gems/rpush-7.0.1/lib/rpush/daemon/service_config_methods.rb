module Rpush
  module Daemon
    module ServiceConfigMethods
      DISPATCHERS = {
        http:       Rpush::Daemon::Dispatcher::Http,
        tcp:        Rpush::Daemon::Dispatcher::Tcp,
        apns_tcp:   Rpush::Daemon::Dispatcher::ApnsTcp,
        apns_http2: Rpush::Daemon::Dispatcher::ApnsHttp2,
        apnsp8_http2: Rpush::Daemon::Dispatcher::Apnsp8Http2
      }

      def batch_deliveries(value = nil)
        return batch_deliveries? if value.nil?
        @batch_deliveries = value
      end

      def batch_deliveries?
        @batch_deliveries == true
      end

      def dispatcher(name = nil, options = {})
        @dispatcher_name = name
        @dispatcher_options = options
      end

      def dispatcher_class
        DISPATCHERS[@dispatcher_name] || (fail NotImplementedError)
      end

      def delivery_class
        const_get('Delivery')
      end

      def new_dispatcher(app)
        dispatcher_class.new(app, delivery_class, @dispatcher_options)
      end

      def loops(classes, options = {})
        classes = Array[*classes]
        @loops = classes.map { |cls| [cls, options] }
      end

      def loop_instances(app)
        (@loops || []).map do |cls, options|
          next unless options.key?(:if) ? options[:if].call : true
          cls.new(app)
        end.compact
      end
    end
  end
end
