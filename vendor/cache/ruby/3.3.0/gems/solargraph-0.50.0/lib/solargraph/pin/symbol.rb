# frozen_string_literal: true

module Solargraph
  module Pin
    class Symbol < Base
      # @param location [Solargraph::Location]
      # @param name [String]
      def initialize location, name
        super(location: location, name: name)
        # @name = name
        # @location = location
      end

      def namespace
        ''
      end

      def path
        ''
      end

      def completion_item_kind
        Solargraph::LanguageServer::CompletionItemKinds::KEYWORD
      end

      def comments
        ''
      end

      def return_type
        @return_type ||= Solargraph::ComplexType::SYMBOL
      end

      def directives
        []
      end

      def visibility
        :public
      end

      def deprecated?
        false
      end
    end
  end
end
