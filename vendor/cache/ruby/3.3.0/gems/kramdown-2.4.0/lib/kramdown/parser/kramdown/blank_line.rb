# -*- coding: utf-8; frozen_string_literal: true -*-
#
#--
# Copyright (C) 2009-2019 Thomas Leitner <t_leitner@gmx.at>
#
# This file is part of kramdown which is licensed under the MIT.
#++
#

module Kramdown
  module Parser
    class Kramdown

      BLANK_LINE = /(?>^\s*\n)+/

      # Parse the blank line at the current postition.
      def parse_blank_line
        @src.pos += @src.matched_size
        if (last_child = @tree.children.last) && last_child.type == :blank
          last_child.value << @src.matched
        else
          @tree.children << new_block_el(:blank, @src.matched)
        end
        true
      end
      define_parser(:blank_line, BLANK_LINE)

    end
  end
end
