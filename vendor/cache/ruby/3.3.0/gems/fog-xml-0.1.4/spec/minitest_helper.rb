require "minitest/spec"
require "minitest/autorun"
require "turn"
require "excon"
require "fog/core"

Turn.config do |c|
  # use one of output formats:
  # :outline  - turn's original case/test outline mode [default]
  # :progress - indicates progress with progress bar
  # :dotted   - test/unit's traditional dot-progress mode
  # :pretty   - new pretty reporter
  # :marshal  - dump output as YAML (normal run mode only)
  # :cue      - interactive testing
  # c.format  = :outline
  # turn on invoke/execute tracing, enable full backtrace
  c.trace   = 20
  # use humanized test names (works only with :outline format)
  c.natural = true
end

if ENV["COVERAGE"]
  require "coveralls"
  require "simplecov"

  SimpleCov.start do
    add_filter "/spec/"
  end
end

require File.join(File.dirname(__FILE__), "../lib/fog/xml")

Coveralls.wear! if ENV["COVERAGE"]
