module Solargraph
  module Parser
    class NodeMethods
      module_function

      def unpack_name node
        raise NotImplementedError
      end

      def infer_literal_type node
        raise NotImplementedError
      end

      def calls_from node
        raise NotImplementedError
      end

      def returns_from node
        raise NotImplementedError
      end

      def process node
        raise NotImplementedError
      end

      def references node
        raise NotImplementedError
      end

      def chain node, filename = nil, in_block = false
        raise NotImplementedError
      end

      def node? node
        raise NotImplementedError
      end

      def convert_hash node
        raise NotImplementedError
      end
    end
  end
end
