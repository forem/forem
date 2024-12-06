# frozen_string_literal: true

class Redis
  # Base error for all redis-rb errors.
  class BaseError < RuntimeError
  end

  # Raised by the connection when a protocol error occurs.
  class ProtocolError < BaseError
    def initialize(reply_type)
      super(<<-EOS.gsub(/(?:^|\n)\s*/, " "))
        Got '#{reply_type}' as initial reply byte.
        If you're in a forking environment, such as Unicorn, you need to
        connect to Redis after forking.
      EOS
    end
  end

  # Raised by the client when command execution returns an error reply.
  class CommandError < BaseError
  end

  # Base error for connection related errors.
  class BaseConnectionError < BaseError
  end

  # Raised when connection to a Redis server cannot be made.
  class CannotConnectError < BaseConnectionError
  end

  # Raised when connection to a Redis server is lost.
  class ConnectionError < BaseConnectionError
  end

  # Raised when performing I/O times out.
  class TimeoutError < BaseConnectionError
  end

  # Raised when the connection was inherited by a child process.
  class InheritedError < BaseConnectionError
  end

  # Raised when client options are invalid.
  class InvalidClientOptionError < BaseError
  end

  class Cluster
    # Raised when client connected to redis as cluster mode
    # and failed to fetch cluster state information by commands.
    class InitialSetupError < BaseError
      # @param errors [Array<Redis::BaseError>]
      def initialize(errors)
        super("Redis client could not fetch cluster information: #{errors.map(&:message).uniq.join(',')}")
      end
    end

    # Raised when client connected to redis as cluster mode
    # and some cluster subcommands were called.
    class OrchestrationCommandNotSupported < BaseError
      def initialize(command, subcommand = '')
        str = [command, subcommand].map(&:to_s).reject(&:empty?).join(' ').upcase
        msg = "#{str} command should be used with care "\
              'only by applications orchestrating Redis Cluster, like redis-trib, '\
              'and the command if used out of the right context can leave the cluster '\
              'in a wrong state or cause data loss.'
        super(msg)
      end
    end

    # Raised when error occurs on any node of cluster.
    class CommandErrorCollection < BaseError
      attr_reader :errors

      # @param errors [Hash{String => Redis::CommandError}]
      # @param error_message [String]
      def initialize(errors, error_message = 'Command errors were replied on any node')
        @errors = errors
        super(error_message)
      end
    end

    # Raised when cluster client can't select node.
    class AmbiguousNodeError < BaseError
      def initialize(command)
        super("Cluster client doesn't know which node the #{command} command should be sent to.")
      end
    end

    # Raised when commands in pipelining include cross slot keys.
    class CrossSlotPipeliningError < BaseError
      def initialize(keys)
        super("Cluster client couldn't send pipelining to single node. "\
              "The commands include cross slot keys. #{keys}")
      end
    end
  end
end
