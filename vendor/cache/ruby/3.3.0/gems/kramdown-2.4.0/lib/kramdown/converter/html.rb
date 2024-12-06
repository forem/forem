# -*- coding: utf-8; frozen_string_literal: true -*-
#
#--
# Copyright (C) 2009-2019 Thomas Leitner <t_leitner@gmx.at>
#
# This file is part of kramdown which is licensed under the MIT.
#++
#

require 'kramdown/parser'
require 'kramdown/converter'
require 'kramdown/utils'

module Kramdown

  module Converter

    # Converts a Kramdown::Document to HTML.
    #
    # You can customize the HTML converter by sub-classing it and overriding the +convert_NAME+
    # methods. Each such method takes the following parameters:
    #
    # [+el+] The element of type +NAME+ to be converted.
    #
    # [+indent+] A number representing the current amount of spaces for indent (only used for
    #            block-level elements).
    #
    # The return value of such a method has to be a string containing the element +el+ formatted as
    # HTML element.
    class Html < Base

      include ::Kramdown::Utils::Html
      include ::Kramdown::Parser::Html::Constants

      # The amount of indentation used when nesting HTML tags.
      attr_accessor :indent

      # Initialize the HTML converter with the given Kramdown document +doc+.
      def initialize(root, options)
        super
        @footnote_counter = @footnote_start = @options[:footnote_nr]
        @footnotes = []
        @footnotes_by_name = {}
        @footnote_location = nil
        @toc = []
        @toc_code = nil
        @indent = 2
        @stack = []

        # stash string representation of symbol to avoid allocations from multiple interpolations.
        @highlighter_class = " highlighter-#{options[:syntax_highlighter]}"
        @dispatcher = Hash.new {|h, k| h[k] = :"convert_#{k}" }
      end

      # Dispatch the conversion of the element +el+ to a +convert_TYPE+ method using the +type+ of
      # the element.
      def convert(el, indent = -@indent)
        send(@dispatcher[el.type], el, indent)
      end

      # Return the converted content of the children of +el+ as a string. The parameter +indent+ has
      # to be the amount of indentation used for the element +el+.
      #
      # Pushes +el+ onto the @stack before converting the child elements and pops it from the stack
      # afterwards.
      def inner(el, indent)
        result = +''
        indent += @indent
        @stack.push(el)
        el.children.each do |inner_el|
          result << send(@dispatcher[inner_el.type], inner_el, indent)
        end
        @stack.pop
        result
      end

      def convert_blank(_el, _indent)
        "\n"
      end

      def convert_text(el, _indent)
        escaped = escape_html(el.value, :text)
        @options[:remove_line_breaks_for_cjk] ? fix_cjk_line_break(escaped) : escaped
      end

      def convert_p(el, indent)
        if el.options[:transparent]
          inner(el, indent)
        elsif el.children.size == 1 && el.children.first.type == :img &&
            el.children.first.options[:ial]&.[](:refs)&.include?('standalone')
          convert_standalone_image(el, indent)
        else
          format_as_block_html("p", el.attr, inner(el, indent), indent)
        end
      end

      # Helper method used by +convert_p+ to convert a paragraph that only contains a single :img
      # element.
      def convert_standalone_image(el, indent)
        figure_attr = el.attr.dup
        image_attr = el.children.first.attr.dup

        figure_attr['class'] = image_attr.delete('class') if image_attr.key?('class') and not figure_attr.key?('class')
        figure_attr['id'] = image_attr.delete('id') if image_attr.key?('id') and not figure_attr.key?('id')

        body = "#{' ' * (indent + @indent)}<img#{html_attributes(image_attr)} />\n" \
          "#{' ' * (indent + @indent)}<figcaption>#{image_attr['alt']}</figcaption>\n"
        format_as_indented_block_html("figure", figure_attr, body, indent)
      end

      def convert_codeblock(el, indent)
        attr = el.attr.dup
        lang = extract_code_language!(attr)
        hl_opts = {}
        highlighted_code = highlight_code(el.value, el.options[:lang] || lang, :block, hl_opts)

        if highlighted_code
          add_syntax_highlighter_to_class_attr(attr, lang || hl_opts[:default_lang])
          "#{' ' * indent}<div#{html_attributes(attr)}>#{highlighted_code}#{' ' * indent}</div>\n"
        else
          result = escape_html(el.value)
          result.chomp!
          if el.attr['class'].to_s =~ /\bshow-whitespaces\b/
            result.gsub!(/(?:(^[ \t]+)|([ \t]+$)|([ \t]+))/) do |m|
              suffix = ($1 ? '-l' : ($2 ? '-r' : ''))
              m.scan(/./).map do |c|
                case c
                when "\t" then "<span class=\"ws-tab#{suffix}\">\t</span>"
                when " " then "<span class=\"ws-space#{suffix}\">&#8901;</span>"
                end
              end.join('')
            end
          end
          code_attr = {}
          code_attr['class'] = "language-#{lang}" if lang
          "#{' ' * indent}<pre#{html_attributes(attr)}>" \
            "<code#{html_attributes(code_attr)}>#{result}\n</code></pre>\n"
        end
      end

      def convert_blockquote(el, indent)
        format_as_indented_block_html("blockquote", el.attr, inner(el, indent), indent)
      end

      def convert_header(el, indent)
        attr = el.attr.dup
        if @options[:auto_ids] && !attr['id']
          attr['id'] = generate_id(el.options[:raw_text])
        end
        @toc << [el.options[:level], attr['id'], el.children] if attr['id'] && in_toc?(el)
        level = output_header_level(el.options[:level])
        format_as_block_html("h#{level}", attr, inner(el, indent), indent)
      end

      def convert_hr(el, indent)
        "#{' ' * indent}<hr#{html_attributes(el.attr)} />\n"
      end

      ZERO_TO_ONETWENTYEIGHT = (0..128).to_a.freeze
      private_constant :ZERO_TO_ONETWENTYEIGHT

      def convert_ul(el, indent)
        if !@toc_code && el.options.dig(:ial, :refs)&.include?('toc')
          @toc_code = [el.type, el.attr, ZERO_TO_ONETWENTYEIGHT.map { rand(36).to_s(36) }.join]
          @toc_code.last
        elsif !@footnote_location && el.options.dig(:ial, :refs)&.include?('footnotes')
          @footnote_location = ZERO_TO_ONETWENTYEIGHT.map { rand(36).to_s(36) }.join
        else
          format_as_indented_block_html(el.type, el.attr, inner(el, indent), indent)
        end
      end
      alias convert_ol convert_ul

      def convert_dl(el, indent)
        format_as_indented_block_html("dl", el.attr, inner(el, indent), indent)
      end

      def convert_li(el, indent)
        output = ' ' * indent << "<#{el.type}" << html_attributes(el.attr) << ">"
        res = inner(el, indent)
        if el.children.empty? || (el.children.first.type == :p && el.children.first.options[:transparent])
          output << res << (res =~ /\n\Z/ ? ' ' * indent : '')
        else
          output << "\n" << res << ' ' * indent
        end
        output << "</#{el.type}>\n"
      end
      alias convert_dd convert_li

      def convert_dt(el, indent)
        attr = el.attr.dup
        @stack.last.options[:ial][:refs].each do |ref|
          if ref =~ /\Aauto_ids(?:-([\w-]+))?/
            attr['id'] = "#{$1}#{basic_generate_id(el.options[:raw_text])}".lstrip
            break
          end
        end if !attr['id'] && @stack.last.options[:ial] && @stack.last.options[:ial][:refs]
        format_as_block_html("dt", attr, inner(el, indent), indent)
      end

      def convert_html_element(el, indent)
        res = inner(el, indent)
        if el.options[:category] == :span
          "<#{el.value}#{html_attributes(el.attr)}" + \
            (res.empty? && HTML_ELEMENTS_WITHOUT_BODY.include?(el.value) ? " />" : ">#{res}</#{el.value}>")
        else
          output = +''
          if @stack.last.type != :html_element || @stack.last.options[:content_model] != :raw
            output << ' ' * indent
          end
          output << "<#{el.value}#{html_attributes(el.attr)}"
          if el.options[:is_closed] && el.options[:content_model] == :raw
            output << " />"
          elsif !res.empty? && el.options[:content_model] != :block
            output << ">#{res}</#{el.value}>"
          elsif !res.empty?
            output << ">\n#{res.chomp}\n" << ' ' * indent << "</#{el.value}>"
          elsif HTML_ELEMENTS_WITHOUT_BODY.include?(el.value)
            output << " />"
          else
            output << "></#{el.value}>"
          end
          output << "\n" if @stack.last.type != :html_element || @stack.last.options[:content_model] != :raw
          output
        end
      end

      def convert_xml_comment(el, indent)
        if el.options[:category] == :block &&
            (@stack.last.type != :html_element || @stack.last.options[:content_model] != :raw)
          ' ' * indent << el.value << "\n"
        else
          el.value
        end
      end
      alias convert_xml_pi convert_xml_comment

      def convert_table(el, indent)
        format_as_indented_block_html(el.type, el.attr, inner(el, indent), indent)
      end
      alias convert_thead convert_table
      alias convert_tbody convert_table
      alias convert_tfoot convert_table
      alias convert_tr convert_table

      ENTITY_NBSP = ::Kramdown::Utils::Entities.entity('nbsp') # :nodoc:

      def convert_td(el, indent)
        res = inner(el, indent)
        type = (@stack[-2].type == :thead ? :th : :td)
        attr = el.attr
        alignment = @stack[-3].options[:alignment][@stack.last.children.index(el)]
        if alignment != :default
          attr = el.attr.dup
          attr['style'] = (attr.key?('style') ? "#{attr['style']}; " : '') + "text-align: #{alignment}"
        end
        format_as_block_html(type, attr, res.empty? ? entity_to_str(ENTITY_NBSP) : res, indent)
      end

      def convert_comment(el, indent)
        if el.options[:category] == :block
          "#{' ' * indent}<!-- #{el.value} -->\n"
        else
          "<!-- #{el.value} -->"
        end
      end

      def convert_br(_el, _indent)
        "<br />"
      end

      def convert_a(el, indent)
        format_as_span_html("a", el.attr, inner(el, indent))
      end

      def convert_img(el, _indent)
        "<img#{html_attributes(el.attr)} />"
      end

      def convert_codespan(el, _indent)
        attr = el.attr.dup
        lang = extract_code_language(attr)
        hl_opts = {}
        result = highlight_code(el.value, lang, :span, hl_opts)
        if result
          add_syntax_highlighter_to_class_attr(attr, lang || hl_opts[:default_lang])
        else
          result = escape_html(el.value)
        end

        format_as_span_html('code', attr, result)
      end

      def convert_footnote(el, _indent)
        repeat = ''
        name = @options[:footnote_prefix] + el.options[:name]
        if (footnote = @footnotes_by_name[name])
          number = footnote[2]
          repeat = ":#{footnote[3] += 1}"
        else
          number = @footnote_counter
          @footnote_counter += 1
          @footnotes << [name, el.value, number, 0]
          @footnotes_by_name[name] = @footnotes.last
        end
        "<sup id=\"fnref:#{name}#{repeat}\" role=\"doc-noteref\">" \
          "<a href=\"#fn:#{name}\" class=\"footnote\" rel=\"footnote\">" \
          "#{number}</a></sup>"
      end

      def convert_raw(el, _indent)
        if !el.options[:type] || el.options[:type].empty? || el.options[:type].include?('html')
          el.value + (el.options[:category] == :block ? "\n" : '')
        else
          ''
        end
      end

      def convert_em(el, indent)
        format_as_span_html(el.type, el.attr, inner(el, indent))
      end
      alias convert_strong convert_em

      def convert_entity(el, _indent)
        entity_to_str(el.value, el.options[:original])
      end

      TYPOGRAPHIC_SYMS = {
        mdash: [::Kramdown::Utils::Entities.entity('mdash')],
        ndash: [::Kramdown::Utils::Entities.entity('ndash')],
        hellip: [::Kramdown::Utils::Entities.entity('hellip')],
        laquo_space: [::Kramdown::Utils::Entities.entity('laquo'),
                      ::Kramdown::Utils::Entities.entity('nbsp')],
        raquo_space: [::Kramdown::Utils::Entities.entity('nbsp'),
                      ::Kramdown::Utils::Entities.entity('raquo')],
        laquo: [::Kramdown::Utils::Entities.entity('laquo')],
        raquo: [::Kramdown::Utils::Entities.entity('raquo')],
      } # :nodoc:
      def convert_typographic_sym(el, _indent)
        if (result = @options[:typographic_symbols][el.value])
          escape_html(result, :text)
        else
          TYPOGRAPHIC_SYMS[el.value].map {|e| entity_to_str(e) }.join('')
        end
      end

      def convert_smart_quote(el, _indent)
        entity_to_str(smart_quote_entity(el))
      end

      def convert_math(el, indent)
        if (result = format_math(el, indent: indent))
          result
        else
          attr = el.attr.dup
          attr['class'] = "#{attr['class']} kdmath".lstrip
          if el.options[:category] == :block
            format_as_block_html('div', attr, "$$\n#{el.value}\n$$", indent)
          else
            format_as_span_html('span', attr, "$#{el.value}$")
          end
        end
      end

      def convert_abbreviation(el, _indent)
        title = @root.options[:abbrev_defs][el.value]
        attr = @root.options[:abbrev_attr][el.value].dup
        attr['title'] = title unless title.empty?
        format_as_span_html("abbr", attr, el.value)
      end

      def convert_root(el, indent)
        result = inner(el, indent)
        if @footnote_location
          result.sub!(/#{@footnote_location}/, footnote_content.gsub(/\\/, "\\\\\\\\"))
        else
          result << footnote_content
        end
        if @toc_code
          toc_tree = generate_toc_tree(@toc, @toc_code[0], @toc_code[1] || {})
          text = if !toc_tree.children.empty?
                   convert(toc_tree, 0)
                 else
                   ''
                 end
          result.sub!(/#{@toc_code.last}/, text.gsub(/\\/, "\\\\\\\\"))
        end
        result
      end

      # Format the given element as span HTML.
      def format_as_span_html(name, attr, body)
        "<#{name}#{html_attributes(attr)}>#{body}</#{name}>"
      end

      # Format the given element as block HTML.
      def format_as_block_html(name, attr, body, indent)
        "#{' ' * indent}<#{name}#{html_attributes(attr)}>#{body}</#{name}>\n"
      end

      # Format the given element as block HTML with a newline after the start tag and indentation
      # before the end tag.
      def format_as_indented_block_html(name, attr, body, indent)
        "#{' ' * indent}<#{name}#{html_attributes(attr)}>\n#{body}#{' ' * indent}</#{name}>\n"
      end

      # Add the syntax highlighter name to the 'class' attribute of the given attribute hash. And
      # overwrites or add a "language-LANG" part using the +lang+ parameter if +lang+ is not nil.
      def add_syntax_highlighter_to_class_attr(attr, lang = nil)
        (attr['class'] = (attr['class'] || '') + @highlighter_class).lstrip!
        attr['class'].sub!(/\blanguage-\S+|(^)/) { "language-#{lang}#{$1 ? ' ' : ''}" } if lang
      end

      # Generate and return an element tree for the table of contents.
      def generate_toc_tree(toc, type, attr)
        sections = Element.new(type, nil, attr.dup)
        sections.attr['id'] ||= 'markdown-toc'
        stack = []
        toc.each do |level, id, children|
          li = Element.new(:li, nil, nil, level: level)
          li.children << Element.new(:p, nil, nil, transparent: true)
          a = Element.new(:a, nil)
          a.attr['href'] = "##{id}"
          a.attr['id'] = "#{sections.attr['id']}-#{id}"
          a.children.concat(fix_for_toc_entry(Marshal.load(Marshal.dump(children))))
          li.children.last.children << a
          li.children << Element.new(type)

          success = false
          until success
            if stack.empty?
              sections.children << li
              stack << li
              success = true
            elsif stack.last.options[:level] < li.options[:level]
              stack.last.children.last.children << li
              stack << li
              success = true
            else
              item = stack.pop
              item.children.pop if item.children.last.children.empty?
            end
          end
        end
        until stack.empty?
          item = stack.pop
          item.children.pop if item.children.last.children.empty?
        end
        sections
      end

      # Fixes the elements for use in a TOC entry.
      def fix_for_toc_entry(elements)
        remove_footnotes(elements)
        unwrap_links(elements)
        elements
      end

      # Remove all link elements by unwrapping them.
      def unwrap_links(elements)
        elements.map! do |c|
          unwrap_links(c.children)
          c.type == :a ? c.children : c
        end.flatten!
      end

      # Remove all footnotes from the given elements.
      def remove_footnotes(elements)
        elements.delete_if do |c|
          remove_footnotes(c.children)
          c.type == :footnote
        end
      end

      # Obfuscate the +text+ by using HTML entities.
      def obfuscate(text)
        result = +''
        text.each_byte do |b|
          result << (b > 128 ? b.chr : sprintf("&#%03d;", b))
        end
        result.force_encoding(text.encoding)
        result
      end

      FOOTNOTE_BACKLINK_FMT = "%s<a href=\"#fnref:%s\" class=\"reversefootnote\" role=\"doc-backlink\">%s</a>"

      # Return an HTML ordered list with the footnote content for the used footnotes.
      def footnote_content
        ol = Element.new(:ol)
        ol.attr['start'] = @footnote_start if @footnote_start != 1
        i = 0
        backlink_text = escape_html(@options[:footnote_backlink], :text)
        while i < @footnotes.length
          name, data, _, repeat = *@footnotes[i]
          li = Element.new(:li, nil, 'id' => "fn:#{name}", 'role' => 'doc-endnote')
          li.children = Marshal.load(Marshal.dump(data.children))

          para = nil
          if li.children.last.type == :p || @options[:footnote_backlink_inline]
            parent = li
            while !parent.children.empty? && ![:p, :header].include?(parent.children.last.type)
              parent = parent.children.last
            end
            para = parent.children.last
            insert_space = true
          end

          unless para
            li.children << (para = Element.new(:p))
            insert_space = false
          end

          unless @options[:footnote_backlink].empty?
            nbsp = entity_to_str(ENTITY_NBSP)
            value = sprintf(FOOTNOTE_BACKLINK_FMT, (insert_space ? nbsp : ''), name, backlink_text)
            para.children << Element.new(:raw, value)
            (1..repeat).each do |index|
              value = sprintf(FOOTNOTE_BACKLINK_FMT, nbsp, "#{name}:#{index}",
                              "#{backlink_text}<sup>#{index + 1}</sup>")
              para.children << Element.new(:raw, value)
            end
          end

          ol.children << Element.new(:raw, convert(li, 4))
          i += 1
        end
        if ol.children.empty?
          ''
        else
          format_as_indented_block_html('div', {class: "footnotes", role: "doc-endnotes"}, convert(ol, 2), 0)
        end
      end

    end

  end
end
