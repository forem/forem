# -*- coding: utf-8; frozen_string_literal: true -*-
#
#--
# Copyright (C) 2009-2019 Thomas Leitner <t_leitner@gmx.at>
#
# This file is part of kramdown which is licensed under the MIT.
#++
#

require 'kramdown/parser/kramdown/block_boundary'

module Kramdown
  module Parser
    class Kramdown

      TABLE_SEP_LINE = /^([+|: \t-]*?-[+|: \t-]*?)[ \t]*\n/
      TABLE_HSEP_ALIGN = /[ \t]?(:?)-+(:?)[ \t]?/
      TABLE_FSEP_LINE = /^[+|: \t=]*?=[+|: \t=]*?[ \t]*\n/
      TABLE_ROW_LINE = /^(.*?)[ \t]*\n/
      TABLE_PIPE_CHECK = /(?:\||.*?[^\\\n]\|)/
      TABLE_LINE = /#{TABLE_PIPE_CHECK}.*?\n/
      TABLE_START = /^#{OPT_SPACE}(?=\S)#{TABLE_LINE}/

      # Parse the table at the current location.
      def parse_table
        return false unless after_block_boundary?

        saved_pos = @src.save_pos
        orig_pos = @src.pos
        table = new_block_el(:table, nil, nil, alignment: [], location: @src.current_line_number)
        leading_pipe = (@src.check(TABLE_LINE) =~ /^\s*\|/)
        @src.scan(TABLE_SEP_LINE)

        rows = []
        has_footer = false
        columns = 0

        add_container = lambda do |type, force|
          if !has_footer || type != :tbody || force
            cont = Element.new(type)
            cont.children, rows = rows, []
            table.children << cont
          end
        end

        until @src.eos?
          break unless @src.check(TABLE_LINE)
          if @src.scan(TABLE_SEP_LINE)
            if rows.empty?
              # nothing to do, ignoring multiple consecutive separator lines
            elsif table.options[:alignment].empty? && !has_footer
              add_container.call(:thead, false)
              table.options[:alignment] = @src[1].scan(TABLE_HSEP_ALIGN).map do |left, right|
                (left.empty? && right.empty? && :default) || (right.empty? && :left) ||
                  (left.empty? && :right) || :center
              end
            else # treat as normal separator line
              add_container.call(:tbody, false)
            end
          elsif @src.scan(TABLE_FSEP_LINE)
            add_container.call(:tbody, true) unless rows.empty?
            has_footer = true
          elsif @src.scan(TABLE_ROW_LINE)
            trow = Element.new(:tr)

            # parse possible code spans on the line and correctly split the line into cells
            env = save_env
            cells = []
            @src[1].split(/(<code.*?>.*?<\/code>)/).each_with_index do |str, i|
              if i.odd?
                (cells.empty? ? cells : cells.last) << str
              else
                reset_env(src: Kramdown::Utils::StringScanner.new(str, @src.current_line_number))
                root = Element.new(:root)
                parse_spans(root, nil, [:codespan])

                root.children.each do |c|
                  if c.type == :raw_text
                    f, *l = c.value.split(/(?<!\\)\|/, -1).map {|t| t.gsub(/\\\|/, '|') }
                    (cells.empty? ? cells : cells.last) << f
                    cells.concat(l)
                  else
                    delim = (c.value.scan(/`+/).max || '') + '`'
                    tmp = +"#{delim}#{' ' if delim.size > 1}#{c.value}#{' ' if delim.size > 1}#{delim}"
                    (cells.empty? ? cells : cells.last) << tmp
                  end
                end
              end
            end
            restore_env(env)

            cells.shift if leading_pipe && cells.first.strip.empty?
            cells.pop if cells.last.strip.empty?
            cells.each do |cell_text|
              tcell = Element.new(:td)
              tcell.children << Element.new(:raw_text, cell_text.strip)
              trow.children << tcell
            end
            columns = [columns, cells.length].max
            rows << trow
          else
            break
          end
        end

        unless before_block_boundary?
          @src.revert_pos(saved_pos)
          return false
        end

        # Parse all lines of the table with the code span parser
        env = save_env
        l_src = ::Kramdown::Utils::StringScanner.new(extract_string(orig_pos...(@src.pos - 1), @src),
                                                     @src.current_line_number)
        reset_env(src: l_src)
        root = Element.new(:root)
        parse_spans(root, nil, [:codespan, :span_html])
        restore_env(env)

        # Check if each line has at least one unescaped pipe that is not inside a code span/code
        # HTML element
        # Note: It doesn't matter that we parse *all* span HTML elements because the row splitting
        # algorithm above only takes <code> elements into account!
        pipe_on_line = false
        while (c = root.children.shift)
          next unless (lines = c.value)
          lines = lines.split("\n")
          if c.type == :codespan
            if lines.size > 2 || (lines.size == 2 && !pipe_on_line)
              break
            elsif lines.size == 2 && pipe_on_line
              pipe_on_line = false
            end
          else
            break if lines.size > 1 && !pipe_on_line && lines.first !~ /^#{TABLE_PIPE_CHECK}/o
            pipe_on_line = (lines.size > 1 ? false : pipe_on_line) || (lines.last =~ /^#{TABLE_PIPE_CHECK}/o)
          end
        end
        @src.revert_pos(saved_pos) and return false unless pipe_on_line

        add_container.call(has_footer ? :tfoot : :tbody, false) unless rows.empty?

        if table.children.none? {|el| el.type == :tbody }
          warning("Found table without body on line #{table.options[:location]} - ignoring it")
          @src.revert_pos(saved_pos)
          return false
        end

        # adjust all table rows to have equal number of columns, same for alignment defs
        table.children.each do |kind|
          kind.children.each do |row|
            (columns - row.children.length).times do
              row.children << Element.new(:td)
            end
          end
        end
        if table.options[:alignment].length > columns
          table.options[:alignment] = table.options[:alignment][0...columns]
        else
          table.options[:alignment] += [:default] * (columns - table.options[:alignment].length)
        end

        @tree.children << table

        true
      end
      define_parser(:table, TABLE_START)

    end
  end
end
