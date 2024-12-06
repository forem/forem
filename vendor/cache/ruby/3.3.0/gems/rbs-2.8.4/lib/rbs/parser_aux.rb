# frozen_string_literal: true

module RBS
  class Parser
    def self.parse_type(source, line: nil, column: nil, range: nil, variables: [])
      buf = buffer(source)
      _parse_type(buf, range&.begin || 0, range&.end || buf.last_position, variables, range.nil?)
    end

    def self.parse_method_type(source, line: nil, column: nil, range: nil, variables: [])
      buf = buffer(source)
      _parse_method_type(buf, range&.begin || 0, range&.end || buf.last_position, variables, range.nil?)
    end

    def self.parse_signature(source, line: nil, column: nil)
      buf = buffer(source)
      _parse_signature(buf, buf.last_position)
    end

    def self.buffer(source)
      case source
      when String
        Buffer.new(content: source, name: "a.rbs")
      when Buffer
        source
      end
    end

    autoload :SyntaxError, "rbs/parser_compat/syntax_error"
    autoload :SemanticsError, "rbs/parser_compat/semantics_error"
    autoload :LexerError, "rbs/parser_compat/lexer_error"
    autoload :LocatedValue, "rbs/parser_compat/located_value"

    KEYWORDS = %w(
      bool
      bot
      class
      instance
      interface
      nil
      self
      singleton
      top
      void
      type
      unchecked
      in
      out
      end
      def
      include
      extend
      prepend
      alias
      module
      attr_reader
      attr_writer
      attr_accessor
      public
      private
      untyped
      true
      false
      ).each_with_object({}) do |keyword, hash|
        hash[keyword] = nil
      end
  end
end
