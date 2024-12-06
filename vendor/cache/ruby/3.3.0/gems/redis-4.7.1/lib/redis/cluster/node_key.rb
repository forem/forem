# frozen_string_literal: true

class Redis
  class Cluster
    # Node key's format is `<ip>:<port>`.
    # It is different from node id.
    # Node id is internal identifying code in Redis Cluster.
    module NodeKey
      DELIMITER = ':'

      module_function

      def optionize(node_key)
        host, port = split(node_key)
        { host: host, port: port }
      end

      def split(node_key)
        node_key.split(DELIMITER)
      end

      def build_from_uri(uri)
        "#{uri.host}#{DELIMITER}#{uri.port}"
      end

      def build_from_host_port(host, port)
        "#{host}#{DELIMITER}#{port}"
      end
    end
  end
end
