# -*- coding: utf-8 -*-
#
#--
# Copyright (C) 2019 Thomas Leitner <t_leitner@gmx.at>
#
# This file is part of kramdown-parser-gfm which is licensed under the MIT.
#++
#

require 'minitest/autorun'
require 'kramdown'
require 'kramdown/parser/gfm'
require 'yaml'
require 'tmpdir'

Encoding.default_external = 'utf-8'

class TestFiles < Minitest::Test

  # Generate test methods for gfm-to-html conversion
  Dir[__dir__ + '/testcases/**/*.text'].each do |text_file|
    basename = text_file.sub(/\.text$/, '')

    html_file = basename + '.html'
    next unless File.exist?(html_file)

    define_method('test_gfm_' + File.basename(text_file, '.*') + '_to_html') do
      opts_file = basename + '.options'
      opts_file = File.join(File.dirname(html_file), 'options') if !File.exist?(opts_file)
      options = File.exist?(opts_file) ? YAML::load(File.read(opts_file)) : {auto_ids: false, footnote_nr: 1}
      doc = Kramdown::Document.new(File.read(text_file), options.merge(input: 'GFM'))
      assert_equal(File.read(html_file), doc.to_html)
    end
  end

end
