# -*- coding: utf-8; frozen_string_literal: true -*-
#
#--
# Copyright (C) 2009-2019 Thomas Leitner <t_leitner@gmx.at>
#
# This file is part of kramdown which is licensed under the MIT.
#++
#

require 'minitest/autorun'
require 'kramdown/utils/string_scanner'

describe Kramdown::Utils::StringScanner do
  [
    ["...........X............", [/X/], 1],
    ["1\n2\n3\n4\n5\n6X", [/X/], 6],
    ["1\n2\n3\n4\n5\n6X\n7\n8X", [/X/, /X/], 8],
    [(".\n" * 1000) + 'X', [/X/], 1001],
  ].each_with_index do |test_data, i|
    test_string, scan_regexes, expect = test_data
    it "computes the correct current_line_number for example ##{i + 1}" do
      str_sc = Kramdown::Utils::StringScanner.new(test_string)
      scan_regexes.each {|scan_re| str_sc.scan_until(scan_re) }
      assert_equal(expect, str_sc.current_line_number)
    end
  end
end
