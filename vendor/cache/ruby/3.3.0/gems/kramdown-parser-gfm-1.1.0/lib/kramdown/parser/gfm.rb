# -*- coding: utf-8; frozen_string_literal: true -*-
#
#--
# Copyright (C) 2019 Thomas Leitner <t_leitner@gmx.at>
#
# This file is part of kramdown-parser-gfm which is licensed under the MIT.
#++
#

require 'kramdown/options'
require 'kramdown/parser/kramdown'

require_relative 'gfm/options'

module Kramdown
  module Parser

    # This class provides a parser implementation for the GFM dialect of Markdown.
    class GFM < Kramdown::Parser::Kramdown

      VERSION = '1.1.0'

      attr_reader :paragraph_end

      def initialize(source, options)
        super
        @options[:auto_id_stripping] = true
        @id_counter = Hash.new(-1)

        @span_parsers.delete(:line_break)       if @options[:hard_wrap]
        @span_parsers.delete(:typographic_syms) if @options[:gfm_quirks].include?(:no_auto_typographic)

        if @options[:gfm_quirks].include?(:paragraph_end)
          atx_header_parser = :atx_header_gfm_quirk
          @paragraph_end    = self.class::PARAGRAPH_END_GFM
        else
          atx_header_parser = :atx_header_gfm
          @paragraph_end    = self.class::PARAGRAPH_END
        end

        {codeblock_fenced: :codeblock_fenced_gfm,
         atx_header: atx_header_parser}.each do |current, replacement|
          i = @block_parsers.index(current)
          @block_parsers.delete(current)
          @block_parsers.insert(i, replacement)
        end

        i = @span_parsers.index(:escaped_chars)
        @span_parsers[i] = :escaped_chars_gfm if i
        @span_parsers << :strikethrough_gfm

        @hard_line_break = "#{@options[:hard_wrap] ? '' : '\\'}\n"
      end

      def parse
        super
        update_elements(@root)
      end

      def update_elements(element)
        element.children.map! do |child|
          if child.type == :text && child.value.include?(@hard_line_break)
            update_text_type(element, child)
          elsif child.type == :html_element
            child
          elsif child.type == :header && @options[:auto_ids] && !child.attr.key?('id')
            child.attr['id'] = generate_gfm_header_id(child.options[:raw_text])
            child
          else
            update_elements(child)
            child
          end
        end.flatten!
      end

      # Update the raw text for automatic ID generation.
      def update_raw_text(item)
        raw_text = +''

        append_text = lambda do |child|
          case child.type
          when :text, :codespan, :math
            raw_text << child.value
          when :entity
            raw_text << child.value.char
          when :smart_quote
            raw_text << ::Kramdown::Utils::Entities.entity(child.value.to_s).char
          when :typographic_sym
            raw_text << case child.value
                        when :laquo_space
                          "« "
                        when :raquo_space
                          " »"
                        else
                          ::Kramdown::Utils::Entities.entity(child.value.to_s).char
                        end
          else
            child.children.each { |c| append_text.call(c) }
          end
        end

        append_text.call(item)
        item.options[:raw_text] = raw_text
      end

      NON_WORD_RE = /[^\p{Word}\- \t]/.freeze

      def generate_gfm_header_id(text)
        result = text.downcase
        result.gsub!(NON_WORD_RE, '')
        result.tr!(" \t", '-')

        @id_counter[result] += 1
        counter_result = @id_counter[result]
        result << "-#{counter_result}" if counter_result > 0

        @options[:auto_id_prefix] + result
      end

      ATX_HEADER_START = /^(?<level>\#{1,6})[\t ]+(?<contents>.*)\n/.freeze
      define_parser(:atx_header_gfm, ATX_HEADER_START, nil, 'parse_atx_header')
      define_parser(:atx_header_gfm_quirk, ATX_HEADER_START)

      # Copied from kramdown/parser/kramdown/header.rb, removed the first line
      def parse_atx_header_gfm_quirk
        text, id = parse_header_contents
        text.sub!(/[\t ]#+\z/, '') && text.rstrip!
        return false if text.empty?

        add_header(@src["level"].length, text, id)
        true
      end

      FENCED_CODEBLOCK_START = /^[ ]{0,3}[~`]{3,}/.freeze
      FENCED_CODEBLOCK_MATCH = /^[ ]{0,3}(([~`]){3,})\s*?((\S+?)(?:\?\S*)?)?\s*?\n(.*?)^[ ]{0,3}\1\2*\s*?\n/m.freeze
      define_parser(:codeblock_fenced_gfm, FENCED_CODEBLOCK_START, nil, 'parse_codeblock_fenced')

      STRIKETHROUGH_DELIM = /~~/.freeze
      STRIKETHROUGH_MATCH = /#{STRIKETHROUGH_DELIM}(?!\s|~).*?[^\s~]#{STRIKETHROUGH_DELIM}/m.freeze
      define_parser(:strikethrough_gfm, STRIKETHROUGH_MATCH, '~~')

      def parse_strikethrough_gfm
        line_number = @src.current_line_number

        @src.pos += @src.matched_size
        el = Element.new(:html_element, 'del', {}, category: :span, line: line_number)
        @tree.children << el

        env = save_env
        reset_env(src: Kramdown::Utils::StringScanner.new(@src.matched[2..-3], line_number),
                  text_type: :text)
        parse_spans(el)
        restore_env(env)

        el
      end

      LIST_TYPES = [:ul, :ol].freeze

      # To handle task-lists we override the parse method for lists, converting matching text into
      # checkbox input elements where necessary (as well as applying classes to the ul/ol and li
      # elements).
      def parse_list
        super
        current_list = @tree.children.select { |element| LIST_TYPES.include?(element.type) }.last

        is_tasklist   = false
        box_unchecked = '<input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />'
        box_checked   = '<input type="checkbox" class="task-list-item-checkbox" ' \
          'disabled="disabled" checked="checked" />'

        current_list.children.each do |li|
          list_items = li.children
          next unless !list_items.empty? && list_items[0].type == :p

          # li -> p -> raw_text
          descendant = list_items[0].children[0].value
          checked    = descendant.gsub!(/\A\s*\[ \]\s+/,  box_unchecked)
          unchecked  = descendant.gsub!(/\A\s*\[x\]\s+/i, box_checked)
          is_tasklist ||= checked || unchecked

          li.attr['class'] = 'task-list-item' if is_tasklist
        end

        current_list.attr['class'] = 'task-list' if is_tasklist

        true
      end

      ESCAPED_CHARS_GFM = /\\([\\.*_+`<>()\[\]{}#!:\|"'\$=\-~])/.freeze
      define_parser(:escaped_chars_gfm, ESCAPED_CHARS_GFM, '\\\\', :parse_escaped_chars)

      PARAGRAPH_END_GFM = Regexp.union(
        LAZY_END, LIST_START, ATX_HEADER_START, DEFINITION_LIST_START,
        BLOCKQUOTE_START, FENCED_CODEBLOCK_START
      )

      private

      def update_text_type(element, child)
        children = []
        lines = child.value.split(@hard_line_break, -1)
        omit_trailing_br = (lines[-1].empty? && Kramdown::Element.category(element) == :block &&
                            element.children[-1] == child)

        lines.each_with_index do |line, index|
          new_element_options = {location: child.options[:location] + index}
          children << Element.new(:text, (index > 0 ? "\n#{line}" : line), nil, new_element_options)

          if index < lines.size - 2 || (index == lines.size - 2 && !omit_trailing_br)
            children << Element.new(:br, nil, nil, new_element_options)
          end
        end

        children
      end

    end
  end
end
