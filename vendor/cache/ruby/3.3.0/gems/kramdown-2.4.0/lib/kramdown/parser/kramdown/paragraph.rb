# -*- coding: utf-8; frozen_string_literal: true -*-
#
#--
# Copyright (C) 2009-2019 Thomas Leitner <t_leitner@gmx.at>
#
# This file is part of kramdown which is licensed under the MIT.
#++
#

require 'kramdown/parser/kramdown/blank_line'
require 'kramdown/parser/kramdown/extensions'
require 'kramdown/parser/kramdown/eob'
require 'kramdown/parser/kramdown/list'
require 'kramdown/parser/kramdown/html'

module Kramdown
  module Parser
    class Kramdown

      LAZY_END_HTML_SPAN_ELEMENTS = HTML_SPAN_ELEMENTS + %w[script]
      LAZY_END_HTML_START = /<(?>(?!(?:#{LAZY_END_HTML_SPAN_ELEMENTS.join('|')})\b)#{REXML::Parsers::BaseParser::UNAME_STR})/
      LAZY_END_HTML_STOP = /<\/(?!(?:#{LAZY_END_HTML_SPAN_ELEMENTS.join('|')})\b)#{REXML::Parsers::BaseParser::UNAME_STR}\s*>/m

      LAZY_END = /#{BLANK_LINE}|#{IAL_BLOCK_START}|#{EOB_MARKER}|^#{OPT_SPACE}#{LAZY_END_HTML_STOP}|^#{OPT_SPACE}#{LAZY_END_HTML_START}|\Z/

      PARAGRAPH_START = /^#{OPT_SPACE}[^ \t].*?\n/
      PARAGRAPH_MATCH = /^.*?\n/
      PARAGRAPH_END = /#{LAZY_END}|#{DEFINITION_LIST_START}/

      # Parse the paragraph at the current location.
      def parse_paragraph
        pos = @src.pos
        start_line_number = @src.current_line_number
        result = @src.scan(PARAGRAPH_MATCH)
        until @src.match?(paragraph_end)
          result << @src.scan(PARAGRAPH_MATCH)
        end
        result.rstrip!
        if (last_child = @tree.children.last) && last_child.type == :p
          last_item_in_para = last_child.children.last
          if last_item_in_para && last_item_in_para.type == @text_type
            joiner = (extract_string((pos - 3)...pos, @src) == "  \n" ? "  \n" : "\n")
            last_item_in_para.value << joiner << result
          else
            add_text(result, last_child)
          end
        else
          @tree.children << new_block_el(:p, nil, nil, location: start_line_number)
          result.lstrip!
          add_text(result, @tree.children.last)
        end
        true
      end
      define_parser(:paragraph, PARAGRAPH_START)

      def paragraph_end
        self.class::PARAGRAPH_END
      end

    end
  end
end
