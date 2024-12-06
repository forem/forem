# frozen_string_literal: true

# Allow lazy loading, only load code if/when there's a syntax error
autoload :DeadEnd, "dead_end/api"

# Ruby 3.2+ has a cleaner way to hook into Ruby that doesn't use `require`
if SyntaxError.new.respond_to?(:detailed_message)
  module DeadEndUnloaded
    class MiniStringIO
      def initialize(isatty: $stderr.isatty)
        @string = +""
        @isatty = isatty
      end

      attr_reader :isatty
      def puts(value = $/, **)
        @string << value
      end

      attr_reader :string
    end
  end

  SyntaxError.prepend Module.new {
    def detailed_message(highlight: nil, **)
      message = super
      file = DeadEnd::PathnameFromMessage.new(message).call.name
      io = DeadEndUnloaded::MiniStringIO.new

      if file
        DeadEnd.call(
          io: io,
          source: file.read,
          filename: file
        )
        annotation = io.string

        annotation + message
      else
        message
      end
    rescue => e
      if ENV["DEBUG"]
        $stderr.warn(e.message)
        $stderr.warn(e.backtrace)
      end

      # Ignore internal errors
      message
    end
  }
else
  autoload :Pathname, "pathname"

  # Monkey patch kernel to ensure that all `require` calls call the same
  # method
  module Kernel
    module_function

    alias_method :dead_end_original_require, :require
    alias_method :dead_end_original_require_relative, :require_relative
    alias_method :dead_end_original_load, :load

    def load(file, wrap = false)
      dead_end_original_load(file)
    rescue SyntaxError => e
      DeadEnd.handle_error(e)
    end

    def require(file)
      dead_end_original_require(file)
    rescue SyntaxError => e
      DeadEnd.handle_error(e)
    end

    def require_relative(file)
      if Pathname.new(file).absolute?
        dead_end_original_require file
      else
        relative_from = caller_locations(1..1).first
        relative_from_path = relative_from.absolute_path || relative_from.path
        dead_end_original_require File.expand_path("../#{file}", relative_from_path)
      end
    rescue SyntaxError => e
      DeadEnd.handle_error(e)
    end
  end
end
