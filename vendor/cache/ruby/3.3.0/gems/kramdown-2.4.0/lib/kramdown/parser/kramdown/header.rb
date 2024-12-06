# -*- coding: utf-8; frozen_string_literal: true -*-
#
#--
# Copyright (C) 2009-2019 Thomas Leitner <t_leitner@gmx.at>
#
# This file is part of kramdown which is licensed under the MIT.
#++
#

require 'kramdown/parser/kramdown/block_boundary'
require 'rexml/xmltokens'

module Kramdown
  module Parser
    class Kramdown

      SETEXT_HEADER_START = /^#{OPT_SPACE}(?<contents>[^ \t].*)\n(?<level>[-=])[-=]*[ \t\r\f\v]*\n/

      # Parse the Setext header at the current location.
      def parse_setext_header
        return false unless after_block_boundary?
        text, id = parse_header_contents
        return false if text.empty?
        add_header(@src["level"] == '-' ? 2 : 1, text, id)
        true
      end
      define_parser(:setext_header, SETEXT_HEADER_START)

      ATX_HEADER_START = /^(?<level>\#{1,6})[\t ]*(?<contents>[^ \t].*)\n/

      # Parse the Atx header at the current location.
      def parse_atx_header
        return false unless after_block_boundary?
        text, id = parse_header_contents
        text.sub!(/(?<!\\)#+\z/, '') && text.rstrip!
        return false if text.empty?
        add_header(@src["level"].length, text, id)
        true
      end
      define_parser(:atx_header, ATX_HEADER_START)

      protected

      HEADER_ID = /[\t ]{#(?<id>#{REXML::XMLTokens::NAME_START_CHAR}#{REXML::XMLTokens::NAME_CHAR}*)}\z/

      # Returns header text and optional ID.
      def parse_header_contents
        text = @src["contents"]
        text.rstrip!
        id_match = HEADER_ID.match(text)
        if id_match
          id = id_match["id"]
          text = text[0...-id_match[0].length]
          text.rstrip!
        end
        [text, id]
      end

      def add_header(level, text, id)
        start_line_number = @src.current_line_number
        @src.pos += @src.matched_size
        el = new_block_el(:header, nil, nil, level: level, raw_text: text, location: start_line_number)
        add_text(text, el)
        el.attr['id'] = id if id
        @tree.children << el
      end

    end
  end
end
