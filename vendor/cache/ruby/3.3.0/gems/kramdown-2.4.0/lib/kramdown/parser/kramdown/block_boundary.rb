# -*- coding: utf-8; frozen_string_literal: true -*-
#
#--
# Copyright (C) 2009-2019 Thomas Leitner <t_leitner@gmx.at>
#
# This file is part of kramdown which is licensed under the MIT.
#++
#

require 'kramdown/parser/kramdown/extensions'
require 'kramdown/parser/kramdown/blank_line'
require 'kramdown/parser/kramdown/eob'

module Kramdown
  module Parser
    class Kramdown

      BLOCK_BOUNDARY = /#{BLANK_LINE}|#{EOB_MARKER}|#{IAL_BLOCK_START}|\Z/

      # Return +true+ if we are after a block boundary.
      def after_block_boundary?
        last_child = @tree.children.last
        !last_child || last_child.type == :blank ||
          (last_child.type == :eob && last_child.value.nil?) || @block_ial
      end

      # Return +true+ if we are before a block boundary.
      def before_block_boundary?
        @src.check(self.class::BLOCK_BOUNDARY)
      end

    end
  end
end
