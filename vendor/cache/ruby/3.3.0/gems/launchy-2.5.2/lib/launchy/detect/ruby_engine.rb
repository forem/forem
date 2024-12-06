module Launchy::Detect
  class RubyEngine
    class NotFoundError < Launchy::Error; end

    extend ::Launchy::DescendantTracker

    # Detect the current ruby engine.
    #
    # If the current ruby engine cannot be detected, the return
    # RubyEngine::Unknown
    def self.detect( ruby_engine = RubyEngine.new )
      found = find_child( :is_current_engine?, ruby_engine.to_s )
      return found if found
      raise NotFoundError, "#{ruby_engine_error_message( ruby_engine )} #{Launchy.bug_report_message}"
    end

    def self.ruby_engine_error_message( ruby_engine )
      msg = "Unkonwn RUBY_ENGINE "
      if ruby_engine then
        msg += " '#{ruby_engine}'."
      elsif defined?( RUBY_ENGINE ) then
        msg += " '#{RUBY_ENGINE}'."
      else
        msg = "RUBY_ENGINE not defined for #{RUBY_DESCRIPTION}."
      end
      return msg
    end

    def self.is_current_engine?( ruby_engine )
      return ruby_engine == self.engine_name
    end

    def self.mri?()     self == Mri;     end
    def self.jruby?()   self == Jruby;   end
    def self.rbx?()     self == Rbx;     end
    def self.macruby?() self == MacRuby; end

    attr_reader :ruby_engine
    alias to_s ruby_engine
    def initialize( ruby_engine = Launchy.ruby_engine )
      if ruby_engine then
        @ruby_engine = ruby_engine
      else
        @ruby_engine = defined?( RUBY_ENGINE ) ? RUBY_ENGINE : "ruby"
      end
    end


    #-------------------------------
    # The list of known ruby engines
    #-------------------------------

    #
    # This is the ruby engine if the RUBY_ENGINE constant is not defined
    class Mri < RubyEngine
      def self.engine_name() "ruby"; end
      def self.is_current_engine?( ruby_engine )
        if ruby_engine then
          super( ruby_engine )
        else
          return true if not Launchy.ruby_engine and not defined?( RUBY_ENGINE )
        end
      end
    end

    class Jruby < RubyEngine
      def self.engine_name() "jruby"; end
    end

    class Rbx < RubyEngine
      def self.engine_name() "rbx"; end
    end

    class MacRuby < RubyEngine
      def self.engine_name() "macruby"; end
    end
  end
end
