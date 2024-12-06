# encoding: utf-8
require 'rubygems/version'

# Load the C-based binding.
begin
  version = Gem::Version.new(RUBY_VERSION)
  require "#{version.segments[0..1].join('.')}/ruby_prof.so"
rescue LoadError
  require "ruby_prof.so"
end

require 'ruby-prof/version'
require 'ruby-prof/call_tree'
require 'ruby-prof/compatibility'
require 'ruby-prof/measurement'
require 'ruby-prof/method_info'
require 'ruby-prof/profile'
require 'ruby-prof/rack'
require 'ruby-prof/thread'

module RubyProf
  autoload :CallTreeVisitor, 'ruby-prof/call_tree_visitor'
  autoload :AbstractPrinter, 'ruby-prof/printers/abstract_printer'
  autoload :CallInfoPrinter, 'ruby-prof/printers/call_info_printer'
  autoload :CallStackPrinter, 'ruby-prof/printers/call_stack_printer'
  autoload :CallTreePrinter, 'ruby-prof/printers/call_tree_printer'
  autoload :DotPrinter, 'ruby-prof/printers/dot_printer'
  autoload :FlatPrinter, 'ruby-prof/printers/flat_printer'
  autoload :GraphHtmlPrinter, 'ruby-prof/printers/graph_html_printer'
  autoload :GraphPrinter, 'ruby-prof/printers/graph_printer'
  autoload :MultiPrinter, 'ruby-prof/printers/multi_printer'

  # :nodoc:
  # Checks if the user specified the clock mode via
  # the RUBY_PROF_MEASURE_MODE environment variable
  def self.figure_measure_mode
    case ENV["RUBY_PROF_MEASURE_MODE"]
    when "wall", "wall_time"
      RubyProf.measure_mode = RubyProf::WALL_TIME
    when "allocations"
      RubyProf.measure_mode = RubyProf::ALLOCATIONS
    when "memory"
      RubyProf.measure_mode = RubyProf::MEMORY
    when "process", "process_time"
      RubyProf.measure_mode = RubyProf::PROCESS_TIME
    else
      # the default is defined in the measure_mode reader
    end
  end
end

RubyProf::figure_measure_mode
