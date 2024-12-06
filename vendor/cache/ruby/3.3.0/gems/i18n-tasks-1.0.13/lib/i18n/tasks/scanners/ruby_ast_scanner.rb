# frozen_string_literal: true

require 'i18n/tasks/scanners/file_scanner'
require 'i18n/tasks/scanners/relative_keys'
require 'i18n/tasks/scanners/ruby_ast_call_finder'
require 'i18n/tasks/scanners/ast_matchers/message_receivers_matcher'
require 'i18n/tasks/scanners/ast_matchers/rails_model_matcher'
require 'parser/current'

module I18n::Tasks::Scanners
  # Scan for I18n.translate calls using whitequark/parser
  class RubyAstScanner < FileScanner
    include RelativeKeys
    include AST::Sexp

    MAGIC_COMMENT_PREFIX = /\A.\s*i18n-tasks-use\s+/.freeze

    def initialize(**args)
      super(**args)
      @parser = ::Parser::CurrentRuby.new
      @magic_comment_parser = ::Parser::CurrentRuby.new
      @matchers = setup_matchers
    end

    protected

    # Extract all occurrences of translate calls from the file at the given path.
    #
    # @return [Array<[key, Results::KeyOccurrence]>] each occurrence found in the file
    def scan_file(path)
      ast, comments = path_to_ast_and_comments(path)

      ast_to_occurences(ast) + comments_to_occurences(path, ast, comments)
    rescue Exception => e # rubocop:disable Lint/RescueException
      raise ::I18n::Tasks::CommandError.new(e, "Error scanning #{path}: #{e.message}")
    end

    # Parse file on path and returns AST and comments.
    #
    # @param path Path to file to parse
    # @return [{Parser::AST::Node}, [Parser::Source::Comment]]
    def path_to_ast_and_comments(path)
      @parser.reset
      @parser.parse_with_comments(make_buffer(path))
    end

    def keys_relative_to_calling_method?(path)
      /controllers|mailers/.match(path)
    end

    # Create an {Parser::Source::Buffer} with the given contents.
    # The contents are assigned a {Parser::Source::Buffer#raw_source}.
    #
    # @param path [String] Path to assign as the buffer name.
    # @param contents [String]
    # @return [Parser::Source::Buffer] file contents
    def make_buffer(path, contents = read_file(path))
      Parser::Source::Buffer.new(path).tap do |buffer|
        buffer.raw_source = contents
      end
    end

    # Convert an array of {Parser::Source::Comment} to occurrences.
    #
    # @param path Path to file
    # @param ast Parser::AST::Node
    # @param comments [Parser::Source::Comment]
    # @return [nil, [key, Occurrence]] full absolute key name and the occurrence.
    def comments_to_occurences(path, ast, comments)
      magic_comments = comments.select { |comment| comment.text =~ MAGIC_COMMENT_PREFIX }
      comment_to_node = Parser::Source::Comment.associate_locations(ast, magic_comments).tap do |h|
        h.transform_values!(&:first)
      end.invert

      magic_comments.flat_map do |comment|
        @parser.reset
        associated_node = comment_to_node[comment]
        ast = @parser.parse(make_buffer(path, comment.text.sub(MAGIC_COMMENT_PREFIX, '').split(/\s+(?=t)/).join('; ')))
        calls = RubyAstCallFinder.new.collect_calls(ast)
        results = []

        # method_name is not available at this stage
        calls.each do |send_node, _method_name|
          @matchers.each do |matcher|
            result = matcher.convert_to_key_occurrences(
              send_node,
              nil,
              location: associated_node || comment.location
            )
            results << result if result
          end
        end

        results
      end
    end

    # Convert {Parser::AST::Node} to occurrences.
    #
    # @param ast {Parser::Source::Comment}
    # @return [nil, [key, Occurrence]] full absolute key name and the occurrence.
    def ast_to_occurences(ast)
      calls = RubyAstCallFinder.new.collect_calls(ast)
      results = []
      calls.each do |send_node, method_name|
        @matchers.each do |matcher|
          result = matcher.convert_to_key_occurrences(send_node, method_name)
          results << result if result
        end
      end

      results
    end

    def setup_matchers
      if config[:receiver_messages]
        config[:receiver_messages].map do |receiver, message|
          AstMatchers::MessageReceiversMatcher.new(
            receivers: [receiver],
            message: message,
            scanner: self
          )
        end
      else
        matchers = %i[t t! translate translate!].map do |message|
          AstMatchers::MessageReceiversMatcher.new(
            receivers: [
              AST::Node.new(:const, [nil, :I18n]),
              nil
            ],
            message: message,
            scanner: self
          )
        end

        Array(config[:ast_matchers]).each do |class_name|
          matchers << ActiveSupport::Inflector.constantize(class_name).new(scanner: self)
        end

        matchers
      end
    end
  end
end
