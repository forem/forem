require "ruby_parser_extras"
require "racc/parser"

##
# RubyParser is a compound parser that uses all known versions to
# attempt to parse.

class RubyParser

  VERSIONS = []

  attr_accessor :current

  def self.for_current_ruby
    name  = "V#{RUBY_VERSION[/^\d+\.\d+/].delete "."}"
    klass = if const_defined? name then
              const_get name
            else
              latest = VERSIONS.first
              warn "NOTE: RubyParser::#{name} undefined, using #{latest}."
              latest
            end

    klass.new
  end

  def self.latest
    VERSIONS.first.new
  end

  def process s, f = "(string)", t = 10
    e = nil
    VERSIONS.each do |klass|
      self.current = parser = klass.new
      begin
        return parser.process s, f, t
      rescue Racc::ParseError, RubyParser::SyntaxError => exc
        e ||= exc
      end
    end
    raise e
  end

  alias :parse :process

  def reset
    # do nothing
  end

  class Parser < Racc::Parser
    include RubyParserStuff

    def self.inherited x
      RubyParser::VERSIONS << x
    end

    def self.version= v
       @version = v
    end

    def self.version
      @version ||= Parser > self && self.name[/(?:V|Ruby)(\d+)/, 1].to_i
    end
  end

  class SyntaxError < RuntimeError; end
end

##
# Unfortunately a problem with racc is that it won't let me namespace
# properly, so instead of RubyParser::V25, I still have to generate
# the old RubyParser25 and shove it in as V25.

require "ruby_parser20"
require "ruby_parser21"
require "ruby_parser22"
require "ruby_parser23"
require "ruby_parser24"
require "ruby_parser25"
require "ruby_parser26"
require "ruby_parser27"
require "ruby_parser30"
require "ruby_parser31"
require "ruby_parser32"
require "ruby_parser33"

class RubyParser # HACK
  VERSIONS.clear # also a HACK caused by racc namespace issues

  class V33 < ::Ruby33Parser; end
  class V32 < ::Ruby32Parser; end
  class V31 < ::Ruby31Parser; end
  class V30 < ::Ruby30Parser; end
  class V27 < ::Ruby27Parser; end
  class V26 < ::Ruby26Parser; end
  class V25 < ::Ruby25Parser; end
  class V24 < ::Ruby24Parser; end
  class V23 < ::Ruby23Parser; end
  class V22 < ::Ruby22Parser; end
  class V21 < ::Ruby21Parser; end
  class V20 < ::Ruby20Parser; end
end
