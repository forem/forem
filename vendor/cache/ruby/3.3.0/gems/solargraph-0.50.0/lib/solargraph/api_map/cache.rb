# frozen_string_literal: true

module Solargraph
  class ApiMap
    class Cache
      def initialize
        @methods = {}
        @constants = {}
        @qualified_namespaces = {}
        @receiver_definitions = {}
      end

      # @return [Array<Pin::Method>]
      def get_methods fqns, scope, visibility, deep
        @methods[[fqns, scope, visibility.sort, deep]]
      end

      def set_methods fqns, scope, visibility, deep, value
        @methods[[fqns, scope, visibility.sort, deep]] = value
      end

      # @return [Array<Pin::Base>]
      def get_constants namespace, context
        @constants[[namespace, context]]
      end

      def set_constants namespace, context, value
        @constants[[namespace, context]] = value
      end

      # @return [String]
      def get_qualified_namespace name, context
        @qualified_namespaces[[name, context]]
      end

      def set_qualified_namespace name, context, value
        @qualified_namespaces[[name, context]] = value
      end

      def receiver_defined? path
        @receiver_definitions.key? path
      end

      # @return [Pin::Method]
      def get_receiver_definition path
        @receiver_definitions[path]
      end

      def set_receiver_definition path, pin
        @receiver_definitions[path] = pin
      end

      # @return [void]
      def clear
        @methods.clear
        @constants.clear
        @qualified_namespaces.clear
        @receiver_definitions.clear
      end

      # @return [Boolean]
      def empty?
        @methods.empty? &&
          @constants.empty? &&
          @qualified_namespaces.empty? &&
          @receiver_definitions.empty?
      end
    end
  end
end
