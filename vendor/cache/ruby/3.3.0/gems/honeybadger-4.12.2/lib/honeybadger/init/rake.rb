require 'honeybadger/ruby'

module Honeybadger
  # @api private
  # Patch Rake::Application to handle errors with Honeybadger
  module RakeHandler
    def self.included(klass)
      klass.class_eval do
        include Rake087Methods unless defined?(Rake::VERSION) && Rake::VERSION >= '0.9.0'
        alias_method :display_error_message_without_honeybadger, :display_error_message
        alias_method :display_error_message, :display_error_message_with_honeybadger
      end
    end

    def display_error_message_with_honeybadger(ex)
      Honeybadger.notify(ex, origin: :rake, component: reconstruct_command_line)
      display_error_message_without_honeybadger(ex)
    ensure
      Honeybadger.clear!
    end

    def reconstruct_command_line
      "rake #{ARGV.join( ' ' )}"
    end

    # This module brings Rake 0.8.7 error handling to 0.9.0 standards
    module Rake087Methods
      # Method taken from Rake 0.9.0 source
      #
      # Provide standard exception handling for the given block.
      def standard_exception_handling
        begin
          yield
        rescue SystemExit => ex
          # Exit silently with current status
          raise
        rescue OptionParser::InvalidOption => ex
          $stderr.puts ex.message
          exit(false)
        rescue Exception => ex
          # Exit with error message
          display_error_message(ex)
          exit(false)
        end
      end

      # Method extracted from Rake 0.8.7 source
      def display_error_message(ex)
        $stderr.puts "#{name} aborted!"
        $stderr.puts ex.message
        if options.trace
          $stderr.puts ex.backtrace.join("\n")
        else
          $stderr.puts ex.backtrace.find {|str| str =~ /#{@rakefile}/ } || ""
          $stderr.puts "(See full trace by running task with --trace)"
        end
      end
    end
  end
end

Rake.application.instance_eval do
  class << self
    include Honeybadger::RakeHandler
  end
end
