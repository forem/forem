# -*- coding: utf-8; frozen_string_literal: true -*-
#
#--
# Copyright (C) 2009-2019 Thomas Leitner <t_leitner@gmx.at>
#
# This file is part of kramdown which is licensed under the MIT.
#++
#

require 'kramdown/converter'
require 'kramdown/utils'

module Kramdown

  module Converter

    # Converts an element tree to the kramdown format.
    class Kramdown < Base

      # :stopdoc:

      include ::Kramdown::Utils::Html

      def initialize(root, options)
        super
        @linkrefs = []
        @footnotes = []
        @abbrevs = []
        @stack = []
        @list_indent = @options[:list_indent]
        @list_spacing = ' ' * (@list_indent - 2)
      end

      def convert(el, opts = {indent: 0})
        res = send("convert_#{el.type}", el, opts)
        res = res.dup if res.frozen?
        if ![:html_element, :li, :dt, :dd, :td].include?(el.type) && (ial = ial_for_element(el))
          res << ial
          res << "\n\n" if el.block?
        elsif [:ul, :dl, :ol, :codeblock].include?(el.type) && opts[:next] &&
            ([el.type, :codeblock].include?(opts[:next].type) ||
             (opts[:next].type == :blank && opts[:nnext] &&
              [el.type, :codeblock].include?(opts[:nnext].type)))
          res << "^\n\n"
        elsif el.block? &&
            ![:li, :dd, :dt, :td, :th, :tr, :thead, :tbody, :tfoot, :blank].include?(el.type) &&
            (el.type != :html_element || @stack.last.type != :html_element) &&
            (el.type != :p || !el.options[:transparent])
          res << "\n"
        end
        res
      end

      def inner(el, opts = {indent: 0})
        @stack.push(el)
        result = +''
        el.children.each_with_index do |inner_el, index|
          options = opts.dup
          options[:index] = index
          options[:prev] = (index == 0 ? nil : el.children[index - 1])
          options[:pprev] = (index <= 1 ? nil : el.children[index - 2])
          options[:next] = (index == el.children.length - 1 ? nil : el.children[index + 1])
          options[:nnext] = (index >= el.children.length - 2 ? nil : el.children[index + 2])
          result << convert(inner_el, options)
        end
        @stack.pop
        result
      end

      def convert_blank(_el, _opts)
        ""
      end

      ESCAPED_CHAR_RE = /(\$\$|[\\*_`\[\]\{"'|])|^[ ]{0,3}(:)/

      def convert_text(el, opts)
        if opts[:raw_text]
          el.value
        else
          el.value.gsub(/\A\n/) do
            opts[:prev] && opts[:prev].type == :br ? '' : "\n"
          end.gsub(/\s+/, ' ').gsub(ESCAPED_CHAR_RE) do
            $1 || !opts[:prev] || opts[:prev].type == :br ? "\\#{$1 || $2}" : $&
          end
        end
      end

      def convert_p(el, opts)
        w = @options[:line_width] - opts[:indent].to_s.to_i
        first, second, *rest = inner(el, opts).strip.gsub(/(.{1,#{w}})( +|$\n?)/, "\\1\n").split(/\n/)
        first&.gsub!(/^(?:(#|>)|(\d+)\.|([+-]\s))/) { $1 || $3 ? "\\#{$1 || $3}" : "#{$2}\\." }
        second&.gsub!(/^([=-]+\s*?)$/, "\\\1")
        res = [first, second, *rest].compact.join("\n") + "\n"
        res.gsub!(/^[ ]{0,3}:/, "\\:")
        if el.children.length == 1 && el.children.first.type == :math
          res = "\\#{res}"
        elsif res.start_with?('\$$') && res.end_with?("\\$$\n")
          res.sub!(/^\\\$\$/, '\$\$')
        end
        res
      end

      def convert_codeblock(el, _opts)
        el.value.split(/\n/).map {|l| l.empty? ? "    " : "    #{l}" }.join("\n") + "\n"
      end

      def convert_blockquote(el, opts)
        opts[:indent] += 2
        inner(el, opts).chomp.split(/\n/).map {|l| "> #{l}" }.join("\n") << "\n"
      end

      def convert_header(el, opts)
        res = +''
        res << "#{'#' * output_header_level(el.options[:level])} #{inner(el, opts)}"
        res[-1, 1] = "\\#" if res[-1] == '#'
        res << "   {##{el.attr['id']}}" if el.attr['id'] && !el.attr['id'].strip.empty?
        res << "\n"
      end

      def convert_hr(_el, _opts)
        "* * *\n"
      end

      def convert_ul(el, opts)
        inner(el, opts).sub(/\n+\Z/, "\n")
      end
      alias convert_ol convert_ul
      alias convert_dl convert_ul

      def convert_li(el, opts)
        sym, width = if @stack.last.type == :ul
                       ['* ' + @list_spacing, el.children.first && el.children.first.type == :codeblock ? 4 : @list_indent]
                     else
                       ["#{opts[:index] + 1}.".ljust(4), 4]
                     end
        if (ial = ial_for_element(el))
          sym << ial << " "
        end

        opts[:indent] += width
        text = inner(el, opts)
        newlines = text.scan(/\n*\Z/).first
        first, *last = text.split(/\n/)
        last = last.map {|l| " " * width + l }.join("\n")
        text = (first.nil? ? "\n" : first + (last.empty? ? "" : "\n") + last + newlines)
        if el.children.first && el.children.first.type == :p && !el.children.first.options[:transparent]
          res = +"#{sym}#{text}"
          res << "^\n" if el.children.size == 1 && @stack.last.children.last == el &&
            (@stack.last.children.any? {|c| c.children.first.type != :p } || @stack.last.children.size == 1)
          res
        elsif el.children.first && el.children.first.type == :codeblock
          "#{sym}\n    #{text}"
        else
          "#{sym}#{text}"
        end
      end

      def convert_dd(el, opts)
        sym, width = ": " + @list_spacing, (el.children.first && el.children.first.type == :codeblock ? 4 : @list_indent)
        if (ial = ial_for_element(el))
          sym << ial << " "
        end

        opts[:indent] += width
        text = inner(el, opts)
        newlines = text.scan(/\n*\Z/).first
        first, *last = text.split(/\n/)
        last = last.map {|l| " " * width + l }.join("\n")
        text = first.to_s + (last.empty? ? "" : "\n") + last + newlines
        text.chomp! if text =~ /\n\n\Z/ && opts[:next] && opts[:next].type == :dd
        text << "\n" if text !~ /\n\n\Z/ && opts[:next] && opts[:next].type == :dt
        text << "\n" if el.children.empty?
        if el.children.first && el.children.first.type == :p && !el.children.first.options[:transparent]
          "\n#{sym}#{text}"
        elsif el.children.first && el.children.first.type == :codeblock
          "#{sym}\n    #{text}"
        else
          "#{sym}#{text}"
        end
      end

      def convert_dt(el, opts)
        result = +''
        if (ial = ial_for_element(el))
          result << ial << " "
        end
        result << inner(el, opts) << "\n"
      end

      HTML_TAGS_WITH_BODY = ['div', 'script', 'iframe', 'textarea', 'th', 'td']

      HTML_ELEMENT_TYPES = [:entity, :text, :html_element].freeze
      private_constant :HTML_ELEMENT_TYPES

      def convert_html_element(el, opts)
        markdown_attr = el.options[:category] == :block && el.children.any? do |c|
          c.type != :html_element &&
            (c.type != :p || !c.options[:transparent] ||
             c.children.any? {|t| !HTML_ELEMENT_TYPES.member?(t.type) }) &&
            c.block?
        end
        opts[:force_raw_text] = true if %w[script pre code].include?(el.value)
        opts[:raw_text] = opts[:force_raw_text] || opts[:block_raw_text] || \
          (el.options[:category] != :span && !markdown_attr)
        opts[:block_raw_text] = true if el.options[:category] == :block && opts[:raw_text]
        res = inner(el, opts)
        if el.options[:category] == :span
          "<#{el.value}#{html_attributes(el.attr)}" + \
            (!res.empty? || HTML_TAGS_WITH_BODY.include?(el.value) ? ">#{res}</#{el.value}>" : " />")
        else
          output = +''
          attr = el.attr.dup
          attr['markdown'] = '1' if markdown_attr
          output << "<#{el.value}#{html_attributes(attr)}"
          if !res.empty? && el.options[:content_model] != :block
            output << ">#{res}</#{el.value}>"
          elsif !res.empty?
            output << ">\n#{res}" << "</#{el.value}>"
          elsif HTML_TAGS_WITH_BODY.include?(el.value)
            output << "></#{el.value}>"
          else
            output << " />"
          end
          output << "\n" if @stack.last.type != :html_element || @stack.last.options[:content_model] != :raw
          output
        end
      end

      def convert_xml_comment(el, _opts)
        if el.options[:category] == :block &&
            (@stack.last.type != :html_element || @stack.last.options[:content_model] != :raw)
          el.value + "\n"
        else
          el.value.dup
        end
      end
      alias convert_xml_pi convert_xml_comment

      def convert_table(el, opts)
        opts[:alignment] = el.options[:alignment]
        inner(el, opts)
      end

      def convert_thead(el, opts)
        rows = inner(el, opts)
        if opts[:alignment].all? {|a| a == :default }
          "#{rows}|#{'-' * 10}\n"
        else
          "#{rows}| " + opts[:alignment].map do |a|
            case a
            when :left then ":-"
            when :right then "-:"
            when :center then ":-:"
            when :default then "-"
            end
          end.join(' ') << "\n"
        end
      end

      def convert_tbody(el, opts)
        res = +''
        res << inner(el, opts)
        res << '|' << '-' * 10 << "\n" if opts[:next] && opts[:next].type == :tbody
        res
      end

      def convert_tfoot(el, opts)
        "|#{'=' * 10}\n#{inner(el, opts)}"
      end

      def convert_tr(el, opts)
        "| #{el.children.map {|c| convert(c, opts) }.join(' | ')} |\n"
      end

      def convert_td(el, opts)
        inner(el, opts)
      end

      def convert_comment(el, _opts)
        if el.options[:category] == :block
          "{::comment}\n#{el.value}\n{:/}\n"
        else
          "{::comment}#{el.value}{:/}"
        end
      end

      def convert_br(_el, _opts)
        "  \n"
      end

      def convert_a(el, opts)
        if el.attr['href'].empty?
          "[#{inner(el, opts)}]()"
        elsif el.attr['href'] =~ /^(?:http|ftp)/ || el.attr['href'].count("()") > 0
          index = if (link_el = @linkrefs.find {|c| c.attr['href'] == el.attr['href'] })
                    @linkrefs.index(link_el) + 1
                  else
                    @linkrefs << el
                    @linkrefs.size
                  end
          "[#{inner(el, opts)}][#{index}]"
        else
          title = parse_title(el.attr['title'])
          "[#{inner(el, opts)}](#{el.attr['href']}#{title})"
        end
      end

      def convert_img(el, _opts)
        alt_text = el.attr['alt'].to_s.gsub(ESCAPED_CHAR_RE) { $1 ? "\\#{$1}" : $2 }
        src = el.attr['src'].to_s
        if src.empty?
          "![#{alt_text}]()"
        else
          title = parse_title(el.attr['title'])
          link = if src.count("()") > 0
                   "<#{src}>"
                 else
                   src
                 end
          "![#{alt_text}](#{link}#{title})"
        end
      end

      def convert_codespan(el, _opts)
        delim = (el.value.scan(/`+/).max || '') + '`'
        "#{delim}#{' ' if delim.size > 1}#{el.value}#{' ' if delim.size > 1}#{delim}"
      end

      def convert_footnote(el, _opts)
        @footnotes << [el.options[:name], el.value]
        "[^#{el.options[:name]}]"
      end

      def convert_raw(el, _opts)
        attr = (el.options[:type] || []).join(' ')
        attr = " type=\"#{attr}\"" unless attr.empty?
        if @stack.last.type == :html_element
          el.value
        elsif el.options[:category] == :block
          "{::nomarkdown#{attr}}\n#{el.value}\n{:/}\n"
        else
          "{::nomarkdown#{attr}}#{el.value}{:/}"
        end
      end

      def convert_em(el, opts)
        "*#{inner(el, opts)}*" +
          (opts[:next] && [:em, :strong].include?(opts[:next].type) && !ial_for_element(el) ? '{::}' : '')
      end

      def convert_strong(el, opts)
        "**#{inner(el, opts)}**" +
          (opts[:next] && [:em, :strong].include?(opts[:next].type) && !ial_for_element(el) ? '{::}' : '')
      end

      def convert_entity(el, _opts)
        entity_to_str(el.value, el.options[:original])
      end

      TYPOGRAPHIC_SYMS = {
        mdash: '---', ndash: '--', hellip: '...',
        laquo_space: '<< ', raquo_space: ' >>',
        laquo: '<<', raquo: '>>'
      }
      def convert_typographic_sym(el, _opts)
        TYPOGRAPHIC_SYMS[el.value]
      end

      def convert_smart_quote(el, _opts)
        el.value.to_s =~ /[rl]dquo/ ? "\"" : "'"
      end

      def convert_math(el, _opts)
        "$$#{el.value}$$" + (el.options[:category] == :block ? "\n" : '')
      end

      def convert_abbreviation(el, _opts)
        el.value
      end

      def convert_root(el, opts)
        res = inner(el, opts)
        res << create_link_defs
        res << create_footnote_defs
        res << create_abbrev_defs
        res
      end

      def create_link_defs
        res = +''
        res << "\n\n" unless @linkrefs.empty?
        @linkrefs.each_with_index do |el, i|
          title = parse_title(el.attr['title'])
          res << "[#{i + 1}]: #{el.attr['href']}#{title}\n"
        end
        res
      end

      def create_footnote_defs
        res = +''
        @footnotes.each do |name, data|
          res << "[^#{name}]:\n"
          res << inner(data).chomp.split(/\n/).map {|l| "    #{l}" }.join("\n") + "\n\n"
        end
        res
      end

      def create_abbrev_defs
        return '' unless @root.options[:abbrev_defs]
        res = +''
        @root.options[:abbrev_defs].each do |name, text|
          res << "*[#{name}]: #{text}\n"
          res << ial_for_element(Element.new(:unused, nil, @root.options[:abbrev_attr][name])).to_s << "\n\n"
        end
        res
      end

      # Return the IAL containing the attributes of the element +el+.
      def ial_for_element(el)
        res = el.attr.map do |k, v|
          next if [:img, :a].include?(el.type) && ['href', 'src', 'alt', 'title'].include?(k)
          next if el.type == :header && k == 'id' && !v.strip.empty?
          if v.nil?
            ''
          elsif k == 'class' && !v.empty? && !v.index(/[\.#]/)
            " " + v.split(/\s+/).map {|w| ".#{w}" }.join(" ")
          elsif k == 'id' && !v.strip.empty?
            " ##{v}"
          else
            " #{k}=\"#{v}\""
          end
        end.compact.join('')
        res = "toc" + (res.strip.empty? ? '' : " #{res}") if (el.type == :ul || el.type == :ol) &&
          el.options.dig(:ial, :refs)&.include?('toc')
        res = "footnotes" + (res.strip.empty? ? '' : " #{res}") if (el.type == :ul || el.type == :ol) &&
          el.options.dig(:ial, :refs)&.include?('footnotes')
        if el.type == :dl && el.options[:ial] && el.options[:ial][:refs]
          auto_ids = el.options[:ial][:refs].select {|ref| ref.start_with?('auto_ids') }.join(" ")
          res = auto_ids << (res.strip.empty? ? '' : " #{res}") unless auto_ids.empty?
        end
        res.strip.empty? ? nil : "{:#{res}}"
      end

      def parse_title(attr)
        attr.to_s.empty? ? '' : ' "' + attr.gsub(/"/, '&quot;') + '"'
      end

      # :startdoc:

    end

  end
end
