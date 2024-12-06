# frozen_string_literal: true

module FrontMatterParser
  # Entry point to parse a front matter from a string or file.
  class Parser
    # @!attribute [r] syntax_parser
    # Current syntax parser in use. See {SyntaxParser}
    attr_reader :syntax_parser

    # @!attribute [r] loader
    # Current loader in use. See {Loader} for details
    attr_reader :loader

    # Parses front matter and content from given pathname, inferring syntax from
    # the extension or, otherwise, using syntax_parser argument.
    #
    # @param pathname [String]
    # @param syntax_parser [Object] see {SyntaxParser}
    # @param loader [Object] see {Loader}
    # @return [Parsed] parsed front matter and content
    def self.parse_file(pathname, syntax_parser: nil, loader: nil)
      syntax_parser ||= syntax_from_pathname(pathname)
      loader ||= Loader::Yaml.new
      File.open(pathname) do |file|
        new(syntax_parser, loader: loader).call(file.read)
      end
    end

    # @!visibility private
    def self.syntax_from_pathname(pathname)
      File.extname(pathname)[1..-1].to_sym
    end

    # @!visibility private
    def self.syntax_parser_from_symbol(syntax)
      Kernel.const_get(
        "FrontMatterParser::SyntaxParser::#{syntax.capitalize}"
      ).new
    end

    # @param syntax_parser [Object] Syntax parser to use. It can be one of two
    #   things:
    #
    #   - An actual object which acts like a parser. See {SyntaxParser} for
    #   details.
    #
    #   - A symbol, in which case it refers to a parser
    #   `FrontMatterParser::SyntaxParser::#{symbol.capitalize}` which can be
    #   initialized without arguments
    #
    # @param loader [Object] Front matter loader to use. See {Loader} for
    # details.
    def initialize(syntax_parser, loader: Loader::Yaml.new)
      @syntax_parser = infer_syntax_parser(syntax_parser)
      @loader = loader
    end

    # Parses front matter and content from given string
    #
    # @param string [String]
    # @return [Parsed] parsed front matter and content
    # :reek:FeatureEnvy
    def call(string)
      match = syntax_parser.call(string)
      front_matter, content =
        if match
          [loader.call(match[:front_matter]), match[:content]]
        else
          [{}, string]
        end
      Parsed.new(front_matter: front_matter, content: content)
    end

    private

    def infer_syntax_parser(syntax_parser)
      return syntax_parser unless syntax_parser.is_a?(Symbol)

      self.class.syntax_parser_from_symbol(syntax_parser)
    end
  end
end
