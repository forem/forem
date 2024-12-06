require "fiber"
require "pry"

module BetterErrors
  module REPL
    class Pry
      class Input
        def readline
          Fiber.yield
        end
      end

      class Output
        def initialize
          @buffer = ""
        end

        def puts(*args)
          args.each do |arg|
            @buffer << "#{arg.chomp}\n"
          end
        end

        def tty?
          false
        end

        def read_buffer
          @buffer
        ensure
          @buffer = ""
        end

        def print(*args)
          @buffer << args.join(' ')
        end
      end

      def initialize(binding, exception)
        @fiber = Fiber.new do
          @pry.repl binding
        end
        @input = BetterErrors::REPL::Pry::Input.new
        @output = BetterErrors::REPL::Pry::Output.new
        @pry = ::Pry.new input: @input, output: @output
        @pry.hooks.clear_all if defined?(@pry.hooks.clear_all)
        store_last_exception exception
        @fiber.resume
      end

      def store_last_exception(exception)
        return unless defined? ::Pry::LastException
        @pry.instance_variable_set(:@last_exception, ::Pry::LastException.new(exception.exception))
      end

      def send_input(str)
        local ::Pry.config, color: false, pager: false do
          @fiber.resume "#{str}\n"
          [@output.read_buffer, *prompt]
        end
      end

      def prompt
        if indent = @pry.instance_variable_get(:@indent) and !indent.indent_level.empty?
          ["..", indent.indent_level]
        else
          [">>", ""]
        end
      rescue
        [">>", ""]
      end

    private
      def local(obj, attrs)
        old_attrs = {}
        attrs.each do |k, v|
          old_attrs[k] = obj.send k
          obj.send "#{k}=", v
        end
        yield
      ensure
        old_attrs.each do |k, v|
          obj.send "#{k}=", v
        end
      end
    end
  end
end
