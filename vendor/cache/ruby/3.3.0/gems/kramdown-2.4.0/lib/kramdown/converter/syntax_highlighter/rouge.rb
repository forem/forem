# -*- coding: utf-8; frozen_string_literal: true -*-
#
#--
# Copyright (C) 2009-2019 Thomas Leitner <t_leitner@gmx.at>
#
# This file is part of kramdown which is licensed under the MIT.
#++
#

module Kramdown::Converter::SyntaxHighlighter

  # Uses Rouge which is CSS-compatible to Pygments to highlight code blocks and code spans.
  module Rouge

    begin
      require 'rouge'

      # Highlighting via Rouge is available if this constant is +true+.
      AVAILABLE = true
    rescue LoadError, SyntaxError
      AVAILABLE = false # :nodoc:
    end

    def self.call(converter, text, lang, type, call_opts)
      opts = options(converter, type)
      call_opts[:default_lang] = opts[:default_lang]
      return nil unless lang || opts[:default_lang] || opts[:guess_lang]

      lexer = ::Rouge::Lexer.find_fancy(lang || opts[:default_lang], text)
      return nil if opts[:disable] || !lexer || (lexer.tag == "plaintext" && !opts[:guess_lang])

      opts[:css_class] ||= 'highlight' # For backward compatibility when using Rouge 2.0
      formatter = formatter_class(opts).new(opts)
      formatter.format(lexer.lex(text))
    end

    def self.options(converter, type)
      prepare_options(converter)
      converter.data[:syntax_highlighter_rouge][type]
    end

    def self.prepare_options(converter)
      return if converter.data.key?(:syntax_highlighter_rouge)

      cache = converter.data[:syntax_highlighter_rouge] = {}

      opts = converter.options[:syntax_highlighter_opts].dup

      span_opts = opts.delete(:span)&.dup || {}
      block_opts = opts.delete(:block)&.dup || {}
      normalize_keys(span_opts)
      normalize_keys(block_opts)

      cache[:span] = opts.merge(span_opts)
      cache[:span][:wrap] = false

      cache[:block] = opts.merge(block_opts)
    end

    def self.normalize_keys(hash)
      return if hash.empty?

      hash.keys.each do |k|
        hash[k.kind_of?(String) ? Kramdown::Options.str_to_sym(k) : k] = hash.delete(k)
      end
    end

    def self.formatter_class(opts = {})
      case formatter = opts[:formatter]
      when Class
        formatter
      when /\A[[:upper:]][[:alnum:]_]*\z/
        ::Rouge::Formatters.const_get(formatter, false)
      else
        # Available in Rouge 2.0 or later
        ::Rouge::Formatters::HTMLLegacy
      end
    rescue NameError
      # Fallback to Rouge 1.x
      ::Rouge::Formatters::HTML
    end

  end

end
