#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)
require 'timeout'

# --  Test for bug [#5657]
# http://rubyforge.org/tracker/index.php?func=detail&aid=5657&group_id=1814&atid=7060


class A
  attr_accessor :as
  def initialize
    @as = []
    class << @as
      def <<(an_a)
        super
      end
    end
  end

  def <<(an_a)
    @as << an_a
  end
end

class SingletonTest < TestCase
  def test_singleton
    result = RubyProf::Profile.profile do
      a = A.new
      a << :first_thing
      assert_equal(1, a.as.size)
    end
    printer = RubyProf::FlatPrinter.new(result)
    output = ENV['SHOW_RUBY_PROF_PRINTER_OUTPUT'] == "1" ? STDOUT : ''
    printer.print(output)
  end
end
