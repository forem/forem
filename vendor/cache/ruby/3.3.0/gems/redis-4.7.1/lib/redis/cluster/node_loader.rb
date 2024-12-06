# frozen_string_literal: true

require 'redis/errors'

class Redis
  class Cluster
    # Load and hashify node info for Redis Cluster Client
    module NodeLoader
      module_function

      def load_flags(nodes)
        errors = nodes.map do |node|
          begin
            return fetch_node_info(node)
          rescue CannotConnectError, ConnectionError, CommandError => error
            error
          end
        end

        raise InitialSetupError, errors
      end

      def fetch_node_info(node)
        node.call(%i[cluster nodes])
            .split("\n")
            .map { |str| str.split(' ') }
            .map { |arr| [arr[1].split('@').first, (arr[2].split(',') & %w[master slave]).first] }
            .to_h
      end

      private_class_method :fetch_node_info
    end
  end
end
