# frozen_string_literal: true

require "better_html_ext"
require_relative "tokenizer/javascript_erb"
require_relative "tokenizer/html_erb"
require_relative "tokenizer/html_lodash"
require_relative "tokenizer/location"
require_relative "tokenizer/token_array"
require_relative "ast/node"
require "parser/source/buffer"

module BetterHtml
  class Parser
    attr_reader :template_language

    class Error < HtmlError
      attr_reader :location
      alias_method :loc, :location

      def initialize(message, location:)
        super(message)
        @location = location
      end
    end

    def initialize(buffer, template_language: :html)
      raise ArgumentError, "first argument must be Parser::Source::Buffer" unless buffer.is_a?(::Parser::Source::Buffer)

      @buffer = buffer
      @template_language = template_language
      @erb = case template_language
      when :html
        Tokenizer::HtmlErb.new(@buffer)
      when :lodash
        Tokenizer::HtmlLodash.new(@buffer)
      when :javascript
        Tokenizer::JavascriptErb.new(@buffer)
      else
        raise ArgumentError, "template_language can be :html or :javascript"
      end
    end

    def nodes_with_type(*type)
      types = Array.wrap(type)
      ast.children.select { |node| node.is_a?(::AST::Node) && types.include?(node.type) }
    end

    def ast
      @ast ||= build_document_node
    end

    def parser_errors
      @erb.parser.errors.map do |error|
        Error.new(
          error.message,
          location: Tokenizer::Location.new(@buffer, error.position, error.position + 1)
        )
      end
    end

    def inspect
      "#<#{self.class.name} ast=#{ast.inspect}>"
    end

    private

    INTERPOLATION_TYPES = [:erb_begin, :lodash_begin]

    def build_document_node
      children = []
      tokens = Tokenizer::TokenArray.new(@erb.tokens)
      while tokens.any?
        case tokens.current.type
        when :cdata_start
          children << build_cdata_node(tokens)
        when :comment_start
          children << build_comment_node(tokens)
        when :tag_start
          children << build_tag_node(tokens)
        when :text, *INTERPOLATION_TYPES
          children << build_text_node(tokens)
        else
          raise "Unhandled token #{tokens.current.type} line #{tokens.current.loc.line} column " \
            "#{tokens.current.loc.column}, #{children.inspect}"
        end
      end

      build_node(:document, children.empty? ? nil : children)
    end

    def build_erb_node(tokens)
      erb_begin = shift_single(tokens, :erb_begin)
      children = [
        shift_single(tokens, :indicator),
        shift_single(tokens, :trim),
        shift_single(tokens, :code),
        shift_single(tokens, :trim),
      ]
      erb_end = shift_single(tokens, :erb_end)

      build_node(:erb, children, pre: erb_begin, post: erb_end)
    end

    def build_lodash_node(tokens)
      lodash_begin = shift_single(tokens, :lodash_begin)
      children = [
        shift_single(tokens, :indicator),
        shift_single(tokens, :code),
      ]
      lodash_end = shift_single(tokens, :lodash_end)

      build_node(:lodash, children, pre: lodash_begin, post: lodash_end)
    end

    def build_cdata_node(tokens)
      cdata_start, children, cdata_end = shift_between_with_interpolation(tokens, :cdata_start, :cdata_end)
      build_node(:cdata, children, pre: cdata_start, post: cdata_end)
    end

    def build_comment_node(tokens)
      comment_start, children, comment_end = shift_between_with_interpolation(tokens, :comment_start, :comment_end)
      build_node(:comment, children, pre: comment_start, post: comment_end)
    end

    def build_tag_node(tokens)
      tag_start, tag_content, tag_end = shift_between(tokens, :tag_start, :tag_end)
      tag_tokens = Tokenizer::TokenArray.new(tag_content)
      tag_tokens.trim(:whitespace)

      children = [
        shift_single(tag_tokens, :solidus),
        build_tag_name_node(tag_tokens),
        build_tag_attributes_node(tag_tokens),
        shift_single(tag_tokens, :solidus),
      ]

      build_node(:tag, children, pre: tag_start, post: tag_end)
    end

    def build_tag_name_node(tokens)
      children = shift_all_with_interpolation(tokens, :tag_name)
      build_node(:tag_name, children) if children.any?
    end

    def build_tag_attributes_node(tokens)
      attributes_tokens = []
      while tokens.any?
        break if tokens.size == 1 && tokens.last.type == :solidus

        if tokens.current.type == :attribute_name
          attributes_tokens << build_attribute_node(tokens)
        elsif tokens.current.type == :attribute_quoted_value_start
          attributes_tokens << build_nameless_attribute_node(tokens)
        elsif tokens.current.type == :erb_begin
          attributes_tokens << build_erb_node(tokens)
        else
          # TODO: warn about ignored things
          tokens.shift
        end
      end

      build_node(:tag_attributes, attributes_tokens) if attributes_tokens.any?
    end

    def build_nameless_attribute_node(tokens)
      value_node = build_attribute_value_node(tokens)
      build_node(:attribute, [nil, nil, value_node])
    end

    def build_attribute_node(tokens)
      name_node = build_attribute_name_node(tokens)
      shift_all(tokens, :whitespace)
      equal_token = shift_single(tokens, :equal)
      shift_all(tokens, :whitespace)
      value_node = build_attribute_value_node(tokens) if equal_token.present?

      build_node(:attribute, [name_node, equal_token, value_node])
    end

    def build_attribute_name_node(tokens)
      children = shift_all_with_interpolation(tokens, :attribute_name)
      build_node(:attribute_name, children)
    end

    def build_attribute_value_node(tokens)
      children = shift_all_with_interpolation(tokens,
        :attribute_quoted_value_start, :attribute_quoted_value,
        :attribute_quoted_value_end, :attribute_unquoted_value)

      build_node(:attribute_value, children)
    end

    def build_text_node(tokens)
      text_tokens = shift_all_with_interpolation(tokens, :text)
      build_node(:text, text_tokens)
    end

    def build_node(type, tokens, pre: nil, post: nil)
      BetterHtml::AST::Node.new(
        type,
        tokens.present? ? wrap_tokens(tokens) : [],
        loc: tokens.present? ? build_location([pre, *tokens, post]) : empty_location
      )
    end

    def build_location(enumerable)
      enumerable = enumerable.compact
      raise ArgumentError, "cannot build location for #{enumerable.inspect}" unless enumerable.first && enumerable.last

      Tokenizer::Location.new(@buffer, enumerable.first.loc.begin_pos, enumerable.last.loc.end_pos)
    end

    def empty_location
      Tokenizer::Location.new(@buffer, 0, 0)
    end

    def shift_all(tokens, *types)
      [].tap do |items|
        while tokens.any?
          if types.include?(tokens.current.type)
            items << tokens.shift
          else
            break
          end
        end
      end
    end

    def shift_single(tokens, *types)
      tokens.shift if tokens.any? && types.include?(tokens.current.type)
    end

    def shift_until(tokens, *types)
      [].tap do |items|
        while tokens.any?
          if !types.include?(tokens.current.type)
            items << tokens.shift
          else
            break
          end
        end
      end
    end

    def build_interpolation_node(tokens)
      if tokens.current.type == :erb_begin
        build_erb_node(tokens)
      elsif tokens.current.type == :lodash_begin
        build_lodash_node(tokens)
      else
        tokens.shift
      end
    end

    def shift_all_with_interpolation(tokens, *types)
      types = [*INTERPOLATION_TYPES, *types]
      [].tap do |result|
        while tokens.any?
          if types.include?(tokens.current.type)
            result << build_interpolation_node(tokens)
          else
            break
          end
        end
      end
    end

    def shift_until_with_interpolation(tokens, *types)
      [].tap do |result|
        while tokens.any?
          if !types.include?(tokens.current.type)
            result << build_interpolation_node(tokens)
          else
            break
          end
        end
      end
    end

    def shift_between(tokens, start_type, end_type)
      start_token = shift_single(tokens, start_type)
      children = shift_until(tokens, end_type)
      end_token = shift_single(tokens, end_type)

      [start_token, children, end_token]
    end

    def shift_between_with_interpolation(tokens, start_type, end_type)
      start_token = shift_single(tokens, start_type)
      children = shift_until_with_interpolation(tokens, end_type)
      end_token = shift_single(tokens, end_type)

      [start_token, children, end_token]
    end

    def wrap_token(object)
      return unless object

      if object.is_a?(::AST::Node)
        object
      elsif [:text, :tag_name, :attribute_name, :attribute_quoted_value,
             :attribute_unquoted_value,].include?(object.type)
        object.loc.source
      elsif [:attribute_quoted_value_start, :attribute_quoted_value_end].include?(object.type)
        BetterHtml::AST::Node.new(:quote, [object.loc.source], loc: object.loc)
      elsif [:indicator, :code].include?(object.type)
        BetterHtml::AST::Node.new(object.type, [object.loc.source], loc: object.loc)
      else
        BetterHtml::AST::Node.new(object.type, [], loc: object.loc)
      end
    end

    def wrap_tokens(enumerable)
      enumerable.map { |object| wrap_token(object) }
    end
  end
end
