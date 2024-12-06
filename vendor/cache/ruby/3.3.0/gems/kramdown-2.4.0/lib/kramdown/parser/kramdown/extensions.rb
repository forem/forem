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

      IAL_CLASS_ATTR = 'class'

      # Parse the string +str+ and extract all attributes and add all found attributes to the hash
      # +opts+.
      def parse_attribute_list(str, opts)
        return if str.strip.empty? || str.strip == ':'
        attrs = str.scan(ALD_TYPE_ANY)
        attrs.each do |key, sep, val, ref, id_and_or_class, _, _|
          if ref
            (opts[:refs] ||= []) << ref
          elsif id_and_or_class
            id_and_or_class.scan(ALD_TYPE_ID_OR_CLASS).each do |id_attr, class_attr|
              if class_attr
                opts[IAL_CLASS_ATTR] = "#{opts[IAL_CLASS_ATTR]} #{class_attr}".lstrip
              else
                opts['id'] = id_attr
              end
            end
          else
            val.gsub!(/\\(\}|#{sep})/, "\\1")
            opts[key] = val
          end
        end
        warning("No or invalid attributes found in IAL/ALD content: #{str}") if attrs.empty?
      end

      # Update the +ial+ with the information from the inline attribute list +opts+.
      def update_ial_with_ial(ial, opts)
        (ial[:refs] ||= []).concat(opts[:refs]) if opts.key?(:refs)
        opts.each do |k, v|
          if k == IAL_CLASS_ATTR
            ial[k] = "#{ial[k]} #{v}".lstrip
          elsif k.kind_of?(String)
            ial[k] = v
          end
        end
      end

      # Parse the generic extension at the current point. The parameter +type+ can either be :block
      # or :span depending whether we parse a block or span extension tag.
      def parse_extension_start_tag(type)
        saved_pos = @src.save_pos
        start_line_number = @src.current_line_number
        @src.pos += @src.matched_size

        error_block = lambda do |msg|
          warning(msg)
          @src.revert_pos(saved_pos)
          add_text(@src.getch) if type == :span
          false
        end

        if @src[4] || @src.matched == '{:/}'
          name = (@src[4] ? "for '#{@src[4]}' " : '')
          return error_block.call("Invalid extension stop tag #{name} found on line " \
                                  "#{start_line_number} - ignoring it")
        end

        ext = @src[1]
        opts = {}
        body = nil
        parse_attribute_list(@src[2] || '', opts)

        unless @src[3]
          stop_re = (type == :block ? /#{EXT_BLOCK_STOP_STR % ext}/ : /#{EXT_STOP_STR % ext}/)
          if (result = @src.scan_until(stop_re))
            body = result.sub!(stop_re, '')
            body.chomp! if type == :block
          else
            return error_block.call("No stop tag for extension '#{ext}' found on line " \
                                    "#{start_line_number} - ignoring it")
          end
        end

        if !handle_extension(ext, opts, body, type, start_line_number)
          error_block.call("Invalid extension with name '#{ext}' specified on line " \
                           "#{start_line_number} - ignoring it")
        else
          true
        end
      end

      def handle_extension(name, opts, body, type, line_no = nil)
        case name
        when 'comment'
          if body.kind_of?(String)
            @tree.children << Element.new(:comment, body, nil, category: type, location: line_no)
          end
          true
        when 'nomarkdown'
          if body.kind_of?(String)
            @tree.children << Element.new(:raw, body, nil, category: type,
                                          location: line_no, type: opts['type'].to_s.split(/\s+/))
          end
          true
        when 'options'
          opts.select do |k, v|
            k = k.to_sym
            if Kramdown::Options.defined?(k)
              if @options[:forbidden_inline_options].include?(k) ||
                  k == :forbidden_inline_options
                warning("Option #{k} may not be set inline")
                next false
              end

              begin
                val = Kramdown::Options.parse(k, v)
                @options[k] = val
                (@root.options[:options] ||= {})[k] = val
              rescue StandardError
              end
              false
            else
              true
            end
          end.each do |k, _v|
            warning("Unknown kramdown option '#{k}'")
          end
          @tree.children << new_block_el(:eob, :extension) if type == :block
          true
        else
          false
        end
      end

      ALD_ID_CHARS = /[\w-]/
      ALD_ANY_CHARS = /\\\}|[^\}]/
      ALD_ID_NAME = /\w#{ALD_ID_CHARS}*/
      ALD_CLASS_NAME = /[^\s\.#]+/
      ALD_TYPE_KEY_VALUE_PAIR = /(#{ALD_ID_NAME})=("|')((?:\\\}|\\\2|[^\}\2])*?)\2/
      ALD_TYPE_CLASS_NAME = /\.(#{ALD_CLASS_NAME})/
      ALD_TYPE_ID_NAME = /#([A-Za-z][\w:-]*)/
      ALD_TYPE_ID_OR_CLASS = /#{ALD_TYPE_ID_NAME}|#{ALD_TYPE_CLASS_NAME}/
      ALD_TYPE_ID_OR_CLASS_MULTI = /((?:#{ALD_TYPE_ID_NAME}|#{ALD_TYPE_CLASS_NAME})+)/
      ALD_TYPE_REF = /(#{ALD_ID_NAME})/
      ALD_TYPE_ANY = /(?:\A|\s)(?:#{ALD_TYPE_KEY_VALUE_PAIR}|#{ALD_TYPE_REF}|#{ALD_TYPE_ID_OR_CLASS_MULTI})(?=\s|\Z)/
      ALD_START = /^#{OPT_SPACE}\{:(#{ALD_ID_NAME}):(#{ALD_ANY_CHARS}+)\}\s*?\n/

      EXT_STOP_STR = "\\{:/(%s)?\\}"
      EXT_START_STR = "\\{::(\\w+)(?:\\s(#{ALD_ANY_CHARS}*?)|)(\\/)?\\}"
      EXT_BLOCK_START = /^#{OPT_SPACE}(?:#{EXT_START_STR}|#{EXT_STOP_STR % ALD_ID_NAME})\s*?\n/
      EXT_BLOCK_STOP_STR = "^#{OPT_SPACE}#{EXT_STOP_STR}\s*?\n"

      IAL_BLOCK = /\{:(?!:|\/)(#{ALD_ANY_CHARS}+)\}\s*?\n/
      IAL_BLOCK_START = /^#{OPT_SPACE}#{IAL_BLOCK}/

      BLOCK_EXTENSIONS_START = /^#{OPT_SPACE}\{:/

      # Parse one of the block extensions (ALD, block IAL or generic extension) at the current
      # location.
      def parse_block_extensions
        if @src.scan(ALD_START)
          parse_attribute_list(@src[2], @alds[@src[1]] ||= {})
          @tree.children << new_block_el(:eob, :ald)
          true
        elsif @src.check(EXT_BLOCK_START)
          parse_extension_start_tag(:block)
        elsif @src.scan(IAL_BLOCK_START)
          if (last_child = @tree.children.last) && last_child.type != :blank &&
              (last_child.type != :eob ||
               [:link_def, :abbrev_def, :footnote_def].include?(last_child.value))
            parse_attribute_list(@src[1], last_child.options[:ial] ||= {})
            @tree.children << new_block_el(:eob, :ial) unless @src.check(IAL_BLOCK_START)
          else
            parse_attribute_list(@src[1], @block_ial ||= {})
          end
          true
        else
          false
        end
      end
      define_parser(:block_extensions, BLOCK_EXTENSIONS_START)

      EXT_SPAN_START = /#{EXT_START_STR}|#{EXT_STOP_STR % ALD_ID_NAME}/
      IAL_SPAN_START = /\{:(#{ALD_ANY_CHARS}+)\}/
      SPAN_EXTENSIONS_START = /\{:/

      # Parse the extension span at the current location.
      def parse_span_extensions
        if @src.check(EXT_SPAN_START)
          parse_extension_start_tag(:span)
        elsif @src.check(IAL_SPAN_START)
          if (last_child = @tree.children.last) && last_child.type != :text
            @src.pos += @src.matched_size
            attr = {}
            parse_attribute_list(@src[1], attr)
            update_ial_with_ial(last_child.options[:ial] ||= {}, attr)
            update_attr_with_ial(last_child.attr, attr)
          else
            warning("Found span IAL after text - ignoring it")
            add_text(@src.getch)
          end
        else
          add_text(@src.getch)
        end
      end
      define_parser(:span_extensions, SPAN_EXTENSIONS_START, '\{:')

    end
  end
end
