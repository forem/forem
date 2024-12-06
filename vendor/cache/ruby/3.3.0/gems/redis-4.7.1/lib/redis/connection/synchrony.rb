# frozen_string_literal: true

require "redis/connection/registry"
require "redis/connection/command_helper"
require "redis/errors"

require "em-synchrony"
require "hiredis/reader"

::Redis.deprecate!(
  "The redis synchrony driver is deprecated and will be removed in redis-rb 5.0.0. " \
  "We're looking for people to maintain it as a separate gem, see https://github.com/redis/redis-rb/issues/915"
)

class Redis
  module Connection
    class RedisClient < EventMachine::Connection
      include EventMachine::Deferrable

      attr_accessor :timeout

      def post_init
        @req = nil
        @connected = false
        @reader = ::Hiredis::Reader.new
      end

      def connection_completed
        @connected = true
        succeed
      end

      def connected?
        @connected
      end

      def receive_data(data)
        @reader.feed(data)

        loop do
          begin
            reply = @reader.gets
          rescue RuntimeError => err
            @req.fail [:error, ProtocolError.new(err.message)]
            break
          end

          break if reply == false

          reply = CommandError.new(reply.message) if reply.is_a?(RuntimeError)
          @req.succeed [:reply, reply]
        end
      end

      def read
        @req = EventMachine::DefaultDeferrable.new
        @req.timeout(@timeout, :timeout) if @timeout > 0
        EventMachine::Synchrony.sync @req
      end

      def send(data)
        callback { send_data data }
      end

      def unbind
        @connected = false
        if @req
          @req.fail [:error, Errno::ECONNRESET]
          @req = nil
        else
          fail
        end
      end
    end

    class Synchrony
      include Redis::Connection::CommandHelper

      def self.connect(config)
        if config[:scheme] == "unix"
          begin
            conn = EventMachine.connect_unix_domain(config[:path], RedisClient)
          rescue RuntimeError => e
            if e.message == "no connection"
              raise Errno::ECONNREFUSED
            else
              raise e
            end
          end
        elsif config[:scheme] == "rediss" || config[:ssl]
          raise NotImplementedError, "SSL not supported by synchrony driver"
        else
          conn = EventMachine.connect(config[:host], config[:port], RedisClient) do |c|
            c.pending_connect_timeout = [config[:connect_timeout], 0.1].max
          end
        end

        fiber = Fiber.current
        conn.callback { fiber.resume }
        conn.errback { fiber.resume :refused }

        raise Errno::ECONNREFUSED if Fiber.yield == :refused

        instance = new(conn)
        instance.timeout = config[:read_timeout]
        instance
      end

      def initialize(connection)
        @connection = connection
      end

      def connected?
        @connection&.connected?
      end

      def timeout=(timeout)
        @connection.timeout = timeout
      end

      def disconnect
        @connection.close_connection
        @connection = nil
      end

      def write(command)
        @connection.send(build_command(command))
      end

      def read
        type, payload = @connection.read

        case type
        when :reply
          payload
        when :error
          raise payload
        when :timeout
          raise TimeoutError
        else
          raise "Unknown type #{type.inspect}"
        end
      end
    end
  end
end

Redis::Connection.drivers << Redis::Connection::Synchrony
