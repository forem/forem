# frozen_string_literal: true

require 'redis/errors'

class Redis
  class Cluster
    # Load details about Redis commands for Redis Cluster Client
    # @see https://redis.io/commands/command
    module CommandLoader
      module_function

      def load(nodes)
        errors = nodes.map do |node|
          begin
            return fetch_command_details(node)
          rescue CannotConnectError, ConnectionError, CommandError => error
            error
          end
        end

        raise InitialSetupError, errors
      end

      def fetch_command_details(node)
        node.call(%i[command]).map do |reply|
          [reply[0], { arity: reply[1], flags: reply[2], first: reply[3], last: reply[4], step: reply[5] }]
        end.to_h
      end

      private_class_method :fetch_command_details
    end
  end
end
