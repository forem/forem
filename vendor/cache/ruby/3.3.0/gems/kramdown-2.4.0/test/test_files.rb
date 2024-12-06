# -*- coding: utf-8; frozen_string_literal: true -*-
#
#--
# Copyright (C) 2009-2019 Thomas Leitner <t_leitner@gmx.at>
#
# This file is part of kramdown which is licensed under the MIT.
#++
#

require 'minitest/autorun'
require 'kramdown'
require 'yaml'
require 'tmpdir'
require 'open3'

begin
  require 'kramdown/converter/syntax_highlighter/rouge'

  Kramdown::Converter::SyntaxHighlighter::Rouge.formatter_class.send(:define_method, :format) do |tokens, &b|
    super(tokens, &b).sub(/<\/code><\/pre>\n?/, "</code></pre>\n")
  end

  # custom formatter for tests
  module Rouge
    module Formatters
      class RougeHTMLFormatters < Kramdown::Converter::SyntaxHighlighter::Rouge.formatter_class

        tag 'rouge_html_formatters'

        def stream(tokens, &b)
          yield %(<div class="custom-class">)
          super
          yield %(</div>)
        end

      end
    end
  end
rescue LoadError, SyntaxError, NameError
end

Encoding.default_external = 'utf-8'

class TestFiles < Minitest::Test

  EXCLUDE_KD_FILES = [].compact

  # Generate test methods for kramdown-to-xxx conversion
  Dir[File.dirname(__FILE__) + '/testcases/**/*.text'].each do |text_file|
    next if EXCLUDE_KD_FILES.any? {|f| text_file =~ /#{f}/ }
    basename = text_file.sub(/\.text$/, '')
    opts_file = text_file.sub(/\.text$/, '.options')
    (Dir[basename + ".*"] - [text_file, opts_file]).each do |output_file|
      output_format = File.extname(output_file)[1..-1]
      next unless Kramdown::Converter.const_defined?(output_format[0..0].upcase + output_format[1..-1])
      define_method('test_' + text_file.tr('.', '_') + "_to_#{output_format}") do
        opts_file = File.join(File.dirname(text_file), 'options') unless File.exist?(opts_file)
        options = File.exist?(opts_file) ? YAML.load(File.read(opts_file)) : {auto_ids: false, footnote_nr: 1}
        doc = Kramdown::Document.new(File.read(text_file), options)
        assert_equal(File.read(output_file), doc.send("to_#{output_format}"))
      end
    end
  end

  # Generate test methods for html-to-{html,kramdown} conversion
  `tidy -v 2>&1`
  if $?.exitstatus != 0
    warn("Skipping html-to-{html,kramdown} tests because tidy executable is missing")
  else
    EXCLUDE_HTML_FILES = [
      'test/testcases/block/06_codeblock/whitespace.html', # bc of span inside pre
      'test/testcases/block/09_html/simple.html', # bc of xml elements
      'test/testcases/span/03_codespan/highlighting.html', # bc of span elements inside code element
      'test/testcases/block/04_header/with_auto_ids.html', # bc of auto_ids=true option
      'test/testcases/block/04_header/header_type_offset.html', # bc of header_offset option
      'test/testcases/block/06_codeblock/rouge/simple.html', # bc of double surrounding <div>
      'test/testcases/block/06_codeblock/rouge/multiple.html', # bc of double surrounding <div>
      'test/testcases/block/06_codeblock/highlighting.html', # bc of span elements inside code element
      'test/testcases/block/06_codeblock/highlighting-opts.html', # bc of span elements inside code element
      'test/testcases/block/06_codeblock/guess_lang_css_class.html', # bc of double surrounding <div>
      'test/testcases/block/12_extension/options3.html', # bc of rouge
      'test/testcases/block/14_table/empty_tag_in_cell.html', # bc of tidy
      'test/testcases/block/15_math/mathjax_preview.html', # bc of mathjax preview
      'test/testcases/block/15_math/mathjax_preview_simple.html', # bc of mathjax preview
      'test/testcases/block/15_math/mathjax_preview_as_code.html', # bc of mathjax preview
      'test/testcases/span/05_html/mark_element.html', # bc of tidy
      'test/testcases/block/09_html/xml.html', # bc of tidy
      'test/testcases/span/05_html/xml.html', # bc of tidy
    ].compact
    EXCLUDE_HTML_TEXT_FILES = [
      'test/testcases/block/09_html/parse_as_span.htmlinput',
      'test/testcases/block/09_html/parse_as_raw.htmlinput',
    ].compact
    Dir[File.dirname(__FILE__) + '/testcases/**/*.{html,htmlinput}'].each do |html_file|
      next if EXCLUDE_HTML_FILES.any? {|f| html_file =~ /#{f}/ }

      out_files = []
      out_files << [(html_file =~ /\.htmlinput$/ ? html_file.sub(/input$/, '') : html_file), :to_html]
      if html_file =~ /\.htmlinput$/ && EXCLUDE_HTML_TEXT_FILES.none? {|f| html_file =~ /#{f}/ }
        out_files << [html_file.sub(/htmlinput$/, 'text'), :to_kramdown]
      end
      out_files.select {|f, _| File.exist?(f) }.each do |out_file, out_method|
        define_method('test_' + html_file.tr('.', '_') + "_to_#{File.extname(out_file)}") do
          opts_file = html_file.sub(/\.html(input)?$/, '.options')
          opts_file = File.join(File.dirname(html_file), 'options') unless File.exist?(opts_file)
          options = File.exist?(opts_file) ? YAML.load(File.read(opts_file)) : {auto_ids: false, footnote_nr: 1}
          doc = Kramdown::Document.new(File.read(html_file), options.merge(input: 'html'))
          if out_method == :to_html
            assert_equal(tidy_output(File.read(out_file)), tidy_output(doc.send(out_method)))
          else
            assert_equal(File.read(out_file), doc.send(out_method))
          end
        end
      end
    end
  end

  def tidy_output(out)
    cmd = "tidy -q --doctype omit -utf8"
    result, error, status = Open3.capture3(cmd, stdin_data: out)
    if status.exitstatus == 2
      raise "Problem using tidy: #{error}"
    end
    result
  end

  # Generate test methods for text-to-latex conversion and compilation
  `latex -v 2>&1`
  if $?.exitstatus != 0
    warn("Skipping latex compilation tests because latex executable is missing")
  else
    EXCLUDE_LATEX_FILES = [
      'test/testcases/span/01_link/image_in_a.text', # bc of image link
      'test/testcases/span/01_link/imagelinks.text', # bc of image links
      'test/testcases/span/01_link/empty_title.text',
      'test/testcases/span/04_footnote/markers.text', # bc of footnote in header
      'test/testcases/block/06_codeblock/with_lang_in_fenced_block_name_with_dash.text',
      'test/testcases/block/06_codeblock/with_lang_in_fenced_block_any_char.text',
      'test/testcases/block/03_paragraph/standalone_image.text', # bc of standalone image
      'test/testcases/cjk-line-break.text', # latex unicode support
    ].compact
    Dir[File.dirname(__FILE__) + '/testcases/**/*.text'].each do |text_file|
      next if EXCLUDE_LATEX_FILES.any? {|f| text_file =~ /#{f}$/ }
      define_method('test_' + text_file.tr('.', '_') + "_to_latex_compilation") do
        latex = Kramdown::Document.new(File.read(text_file), auto_ids: false, footnote_nr: 1,
                                       template: 'document').to_latex
        Dir.mktmpdir do |tmpdir|
          result = IO.popen("latex -output-directory='#{tmpdir}' 2>/dev/null", 'r+') do |io|
            io.write(latex)
            io.close_write
            io.read
          end
          assert($?.exitstatus == 0, result.scan(/^!(.*\n.*)/).join("\n"))
        end
      end
    end
  end

  # Generate test methods for text->kramdown->html conversion
  `tidy -v 2>&1`
  if $?.exitstatus != 0
    warn("Skipping text->kramdown->html tests because tidy executable is missing")
  else
    EXCLUDE_TEXT_FILES = [
      'test/testcases/span/05_html/markdown_attr.text',  # bc of markdown attr
      'test/testcases/block/09_html/markdown_attr.text', # bc of markdown attr
      'test/testcases/span/extension/options.text',      # bc of parse_span_html option
      'test/testcases/block/12_extension/options.text',  # bc of options option
      'test/testcases/block/12_extension/options3.text', # bc of options option
      'test/testcases/block/09_html/content_model/tables.text',  # bc of parse_block_html option
      'test/testcases/block/09_html/html_to_native/header.text', # bc of auto_ids option that interferes
      'test/testcases/block/09_html/html_to_native/table_simple.text', # bc of tr style attr getting removed
      'test/testcases/block/09_html/simple.text',        # bc of webgen:block elements
      'test/testcases/block/11_ial/simple.text',         # bc of change of ordering of attributes in header
      'test/testcases/span/extension/comment.text',      # bc of comment text modifications (can this be avoided?)
      'test/testcases/block/04_header/header_type_offset.text', # bc of header_offset being applied twice
      'test/testcases/block/06_codeblock/rouge/simple.text',
      'test/testcases/block/06_codeblock/rouge/multiple.text', # check, what document contain more, than one code block
      'test/testcases/block/14_table/empty_tag_in_cell.text', # bc of tidy
      'test/testcases/span/01_link/link_defs_with_ial.text', # bc of attribute ordering
      'test/testcases/span/05_html/mark_element.text', # bc of tidy
      'test/testcases/block/09_html/xml.text', # bc of tidy
      'test/testcases/span/05_html/xml.text', # bc of tidy
      'test/testcases/block/03_paragraph/standalone_image.text', # bc of standalone image
      'test/testcases/cjk-line-break.text',
      'test/testcases/block/09_html/standalone_image_in_div.html', # bc of standalone image
      'test/testcases/span/abbreviations/abbrev_in_html.text', # bc of invalid abbr tag in SVG
    ].compact
    Dir[File.dirname(__FILE__) + '/testcases/**/*.text'].each do |text_file|
      next if EXCLUDE_TEXT_FILES.any? {|f| text_file =~ /#{f}$/ }
      html_file = text_file.sub(/\.text$/, '.html')
      next unless File.exist?(html_file)
      define_method('test_' + text_file.tr('.', '_') + "_to_kramdown_to_html") do
        opts_file = text_file.sub(/\.text$/, '.options')
        opts_file = File.join(File.dirname(text_file), 'options') unless File.exist?(opts_file)
        options = File.exist?(opts_file) ? YAML.load(File.read(opts_file)) : {auto_ids: false, footnote_nr: 1}
        kdtext = Kramdown::Document.new(File.read(text_file), options).to_kramdown
        html = Kramdown::Document.new(kdtext, options).to_html
        assert_equal(tidy_output(File.read(html_file)), tidy_output(html))
        kdtext4 = Kramdown::Document.new(File.read(text_file), options.merge({list_indent: 4})).to_kramdown
        html = Kramdown::Document.new(kdtext4, options).to_html
        assert_equal(tidy_output(File.read(html_file)), tidy_output(html))
      end
    end
  end

  # Generate test methods for html-to-kramdown-to-html conversion
  `tidy -v 2>&1`
  if $?.exitstatus != 0
    warn("Skipping html-to-kramdown-to-html tests because tidy executable is missing")
  else
    EXCLUDE_HTML_KD_FILES = [
      'test/testcases/span/extension/options.html',        # bc of parse_span_html option
      'test/testcases/span/05_html/normal.html',           # bc of br tag before closing p tag
      'test/testcases/block/12_extension/nomarkdown.html', # bc of nomarkdown extension
      'test/testcases/block/12_extension/options3.html', # bc of rouge
      'test/testcases/block/09_html/simple.html',          # bc of webgen:block elements
      'test/testcases/block/09_html/markdown_attr.html',   # bc of markdown attr
      'test/testcases/block/09_html/html_to_native/table_simple.html', # bc of invalidly converted simple table
      'test/testcases/block/06_codeblock/whitespace.html', # bc of entity to char conversion
      'test/testcases/block/06_codeblock/rouge/simple.html', # bc of double surrounding <div>
      'test/testcases/block/06_codeblock/rouge/multiple.html', # bc of double surrounding <div>
      'test/testcases/block/06_codeblock/guess_lang_css_class.html', # bc of double surrounding <div>
      'test/testcases/block/06_codeblock/highlighting.html', # bc of span elements inside code element
      'test/testcases/block/06_codeblock/highlighting-opts.html', # bc of span elements inside code element
      'test/testcases/block/11_ial/simple.html',           # bc of change of ordering of attributes in header
      'test/testcases/span/03_codespan/highlighting.html', # bc of span elements inside code element
      'test/testcases/block/04_header/with_auto_ids.html', # bc of auto_ids=true option
      'test/testcases/block/04_header/header_type_offset.html', # bc of header_offset option
      'test/testcases/block/16_toc/toc_exclude.html',      # bc of different attribute ordering
      'test/testcases/span/autolinks/url_links.html',      # bc of quot entity being converted to char
      'test/testcases/block/14_table/empty_tag_in_cell.html', # bc of tidy
      'test/testcases/span/01_link/link_defs_with_ial.html', # bc of attribute ordering
      'test/testcases/span/05_html/mark_element.html', # bc of tidy
      'test/testcases/block/09_html/xml.html', # bc of tidy
      'test/testcases/span/05_html/xml.html', # bc of tidy
      'test/testcases/block/03_paragraph/standalone_image.html', # bc of standalone image
      'test/testcases/block/15_math/normal.html', # bc of mathjax and HTML parser
      'test/testcases/block/15_math/gh_128.html', # bc of mathjax and HTML parser
      'test/testcases/span/04_footnote/backlink_inline.html', # bc of mathjax
      'test/testcases/block/09_html/standalone_image_in_div.html', # bc of standalone image
      'test/testcases/block/09_html/processing_instruction.html', # bc of PI
    ].compact
    Dir[File.dirname(__FILE__) + '/testcases/**/*.html'].each do |html_file|
      next if EXCLUDE_HTML_KD_FILES.any? {|f| html_file =~ /#{f}$/ }
      define_method('test_' + html_file.tr('.', '_') + "_to_kramdown_to_html") do
        kd = Kramdown::Document.new(File.read(html_file), input: 'html',
                                    auto_ids: false, footnote_nr: 1).to_kramdown
        opts_file = html_file.sub(/\.html$/, '.options')
        opts_file = File.join(File.dirname(html_file), 'options') unless File.exist?(opts_file)
        options = File.exist?(opts_file) ? YAML.load(File.read(opts_file)) : {auto_ids: false, footnote_nr: 1}
        doc = Kramdown::Document.new(kd, options)
        assert_equal(tidy_output(File.read(html_file)), tidy_output(doc.to_html))
      end
    end
  end

  # Generate test methods for text-manpage conversion
  Dir[File.dirname(__FILE__) + '/testcases/man/**/*.text'].each do |text_file|
    define_method('test_' + text_file.tr('.', '_') + "_to_man") do
      man_file = text_file.sub(/\.text$/, '.man')
      doc = Kramdown::Document.new(File.read(text_file))
      assert_equal(File.read(man_file), doc.to_man)
    end
  end

  EXCLUDE_MODIFY = [
    'test/testcases/block/06_codeblock/rouge/multiple.text', # bc of HTMLFormater in options
  ].compact

  # Generate test methods for asserting that converters don't modify the document tree.
  Dir[File.dirname(__FILE__) + '/testcases/**/*.text'].each do |text_file|
    opts_file = text_file.sub(/\.text$/, '.options')
    options = File.exist?(opts_file) ? YAML.load(File.read(opts_file)) : {auto_ids: false, footnote_nr: 1}
    (Kramdown::Converter.constants.map(&:to_sym) -
     [:Base, :RemoveHtmlTags, :MathEngine, :SyntaxHighlighter]).each do |conv_class|
      next if EXCLUDE_MODIFY.any? {|f| text_file =~ /#{f}$/ }
      define_method("test_whether_#{conv_class}_modifies_tree_with_file_#{text_file.tr('.', '_')}") do
        doc = Kramdown::Document.new(File.read(text_file), options)
        options_before = Marshal.load(Marshal.dump(doc.options))
        tree_before = Marshal.load(Marshal.dump(doc.root))
        Kramdown::Converter.const_get(conv_class).convert(doc.root, doc.options)
        assert_equal(options_before, doc.options)
        assert_tree_not_changed(tree_before, doc.root)
      end
    end
  end

  def assert_tree_not_changed(old, new)
    assert_equal(old.type, new.type, "type mismatch")
    if old.value.kind_of?(Kramdown::Element)
      assert_tree_not_changed(old.value, new.value)
    else
      assert(old.value == new.value, "value mismatch")
    end
    assert_equal(old.attr, new.attr, "attr mismatch")
    assert_equal(old.options, new.options, "options mismatch")
    assert_equal(old.children.length, new.children.length, "children count mismatch")

    old.children.each_with_index do |child, index|
      assert_tree_not_changed(child, new.children[index])
    end
  end

end
