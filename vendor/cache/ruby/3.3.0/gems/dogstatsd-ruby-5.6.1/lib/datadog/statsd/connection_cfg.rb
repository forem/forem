module Datadog
  class Statsd
    class ConnectionCfg
      attr_reader :host
      attr_reader :port
      attr_reader :socket_path
      attr_reader :transport_type

      def initialize(host: nil, port: nil, socket_path: nil)
        initialize_with_constructor_args(host: host, port: port, socket_path: socket_path) ||
          initialize_with_env_vars ||
          initialize_with_defaults
      end

      def make_connection(**params)
        case @transport_type
        when :udp
          UDPConnection.new(@host, @port, **params)
        when :uds
          UDSConnection.new(@socket_path, **params)
        end
      end

      private

      ERROR_MESSAGE = "Valid environment variables combination for connection configuration:\n" +
                      "  - DD_DOGSTATSD_URL for UDP or UDS connection.\n" +
                      "     Example for UDP: DD_DOGSTATSD_URL='udp://localhost:8125'\n" +
                      "     Example for UDS: DD_DOGSTATSD_URL='unix:///path/to/unix.sock'\n" +
                      "  or\n" +
                      "  - DD_AGENT_HOST and DD_DOGSTATSD_PORT for an UDP connection. E.g. DD_AGENT_HOST='localhost' DD_DOGSTATSD_PORT=8125\n" +
                      "  or\n" +
                      "  - DD_DOGSTATSD_SOCKET for an UDS connection: E.g. DD_DOGSTATSD_SOCKET='/path/to/unix.sock'\n" +
                      " Note that DD_DOGSTATSD_URL has priority on other environment variables."

      DEFAULT_HOST = '127.0.0.1'
      DEFAULT_PORT = 8125

      UDP_PREFIX = 'udp://'
      UDS_PREFIX = 'unix://'

      def initialize_with_constructor_args(host: nil, port: nil, socket_path: nil)
        try_initialize_with(host: host, port: port, socket_path: socket_path,
          error_message: 
            "Both UDP: (host/port #{host}:#{port}) and UDS (socket_path #{socket_path}) " +
            "constructor arguments were given. Use only one or the other.",
          )
      end

      def initialize_with_env_vars()
        try_initialize_with(
          dogstatsd_url: ENV['DD_DOGSTATSD_URL'],
          host: ENV['DD_AGENT_HOST'],
          port: ENV['DD_DOGSTATSD_PORT'] && ENV['DD_DOGSTATSD_PORT'].to_i,
          socket_path: ENV['DD_DOGSTATSD_SOCKET'],
          error_message: ERROR_MESSAGE,
        )
      end

      def initialize_with_defaults()
        try_initialize_with(host: DEFAULT_HOST, port: DEFAULT_PORT)
      end

      def try_initialize_with(dogstatsd_url: nil, host: nil, port: nil, socket_path: nil, error_message: ERROR_MESSAGE)
        if (host || port) && socket_path
          raise ArgumentError, error_message
        end

        if dogstatsd_url
          host, port, socket_path = parse_dogstatsd_url(str: dogstatsd_url.to_s)
        end

        if host || port 
          @host = host || DEFAULT_HOST
          @port = port || DEFAULT_PORT
          @socket_path = nil
          @transport_type = :udp
          return true
        elsif socket_path
          @host = nil
          @port = nil
          @socket_path = socket_path
          @transport_type = :uds
          return true
        end

        return false
      end

      def parse_dogstatsd_url(str:)
        # udp socket connection

        if str.start_with?(UDP_PREFIX)
          dogstatsd_url = str[UDP_PREFIX.size..str.size]
          host = nil
          port = nil

          if dogstatsd_url.include?(":")
            parts = dogstatsd_url.split(":")
            if parts.size > 2
              raise ArgumentError, "Error: DD_DOGSTATSD_URL wrong format for an UDP connection. E.g. 'udp://localhost:8125'"
            end

            host = parts[0]
            port = parts[1].to_i
          else
            host = dogstatsd_url
          end

          return host, port, nil
        end

        # unix socket connection

        if str.start_with?(UDS_PREFIX)
          return nil, nil, str[UDS_PREFIX.size..str.size]
        end

        # malformed value

        raise ArgumentError, "Error: DD_DOGSTATSD_URL has been provided but is not starting with 'udp://' nor 'unix://'"
      end
    end
  end
end
