#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

class AbstractPrinterTest < TestCase
  def setup
    super
    @result = {}
    @printer = RubyProf::AbstractPrinter.new(@result)
    @options = {}
    @printer.setup_options(@options)
  end

  private

  def with_const_stubbed(name, value)
    old_verbose, $VERBOSE = $VERBOSE, nil
    old_value = Object.const_get(name)

    Object.const_set(name, value)
    yield
    Object.const_set(name, old_value)

    $VERBOSE = old_verbose
  end
end
