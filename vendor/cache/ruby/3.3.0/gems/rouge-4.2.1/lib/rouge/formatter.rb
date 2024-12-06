# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  # A Formatter takes a token stream and formats it for human viewing.
  class Formatter
    # @private
    REGISTRY = {}

    # Specify or get the unique tag for this formatter.  This is used
    # for specifying a formatter in `rougify`.
    def self.tag(tag=nil)
      return @tag unless tag
      REGISTRY[tag] = self

      @tag = tag
    end

    # Find a formatter class given a unique tag.
    def self.find(tag)
      REGISTRY[tag]
    end

    def self.with_escape
      Thread.current[:'rouge/with-escape'] = true
      yield
    ensure
      Thread.current[:'rouge/with-escape'] = false
    end

    def self.escape_enabled?
      !!(((defined? @escape_enabled) && @escape_enabled) || Thread.current[:'rouge/with-escape'])
    end

    def self.enable_escape!
      @escape_enabled = true
    end

    def self.disable_escape!
      @escape_enabled = false
      Thread.current[:'rouge/with-escape'] = false
    end

    # Format a token stream.  Delegates to {#format}.
    def self.format(tokens, *args, **kwargs, &b)
      new(*args, **kwargs).format(tokens, &b)
    end

    def initialize(opts={})
      # pass
    end

    def escape?(tok)
      tok == Token::Tokens::Escape
    end

    def filter_escapes(tokens)
      tokens.each do |t, v|
        if t == Token::Tokens::Escape
          yield Token::Tokens::Error, v
        else
          yield t, v
        end
      end
    end

    # Format a token stream.
    def format(tokens, &b)
      tokens = enum_for(:filter_escapes, tokens) unless Formatter.escape_enabled?

      return stream(tokens, &b) if block_given?

      out = String.new('')
      stream(tokens) { |piece| out << piece }

      out
    end

    # @deprecated Use {#format} instead.
    def render(tokens)
      warn 'Formatter#render is deprecated, use #format instead.'
      format(tokens)
    end

    # @abstract
    # yield strings that, when concatenated, form the formatted output
    def stream(tokens, &b)
      raise 'abstract'
    end

  protected
    def token_lines(tokens, &b)
      return enum_for(:token_lines, tokens) unless block_given?

      out = []
      tokens.each do |tok, val|
        val.scan %r/\n|[^\n]+/ do |s|
          if s == "\n"
            yield out
            out = []
          else
            out << [tok, s]
          end
        end
      end

      # for inputs not ending in a newline
      yield out if out.any?
    end

  end
end
