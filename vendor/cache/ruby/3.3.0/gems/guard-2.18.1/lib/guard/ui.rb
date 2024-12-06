require "guard/ui/colors"
require "guard/ui/config"

require "guard/terminal"
require "forwardable"

# TODO: rework this class from the bottom-up
#  - remove dependency on Session and Scope
#  - extract into a separate gem
# - change UI to class

module Guard
  # The UI class helps to format messages for the user. Everything that is
  # logged through this class is considered either as an error message or a
  # diagnostic message and is written to standard error ($stderr).
  #
  # If your Guard plugin does some output that is piped into another process
  # for further processing, please just write it to STDOUT with `puts`.
  #
  module UI
    include Colors

    class << self
      # Get the Guard::UI logger instance
      #
      def logger
        @logger ||=
          begin
            require "lumberjack"
            Lumberjack::Logger.new(options.device, options.logger_config)
          end
      end

      # Since logger is global, for Aruba in-process to properly
      # separate output between calls, we need to reset
      #
      # We don't use logger=() since it's expected to be a Lumberjack instance
      def reset_logger
        @logger = nil
      end

      # Get the logger options
      #
      # @return [Hash] the logger options
      #
      def options
        @options ||= Config.new
      end

      # Set the logger options
      #
      # @param [Hash] options the logger options
      # @option options [Symbol] level the log level
      # @option options [String] template the logger template
      # @option options [String] time_format the time format
      #
      # TODO: deprecate?
      def options=(options)
        @options = Config.new(options)
      end

      # Assigns a log level
      def level=(new_level)
        options.logger_config.level = new_level
        @logger.level = new_level if @logger
      end

      # Show an info message.
      #
      # @param [String] message the message to show
      # @option options [Boolean] reset whether to clean the output before
      # @option options [String] plugin manually define the calling plugin
      #
      def info(message, options = {})
        _filtered_logger_message(message, :info, nil, options)
      end

      # Show a yellow warning message that is prefixed with WARNING.
      #
      # @param [String] message the message to show
      # @option options [Boolean] reset whether to clean the output before
      # @option options [String] plugin manually define the calling plugin
      #
      def warning(message, options = {})
        _filtered_logger_message(message, :warn, :yellow, options)
      end

      # Show a red error message that is prefixed with ERROR.
      #
      # @param [String] message the message to show
      # @option options [Boolean] reset whether to clean the output before
      # @option options [String] plugin manually define the calling plugin
      #
      def error(message, options = {})
        _filtered_logger_message(message, :error, :red, options)
      end

      # Show a red deprecation message that is prefixed with DEPRECATION.
      # It has a log level of `warn`.
      #
      # @param [String] message the message to show
      # @option options [Boolean] reset whether to clean the output before
      # @option options [String] plugin manually define the calling plugin
      #
      def deprecation(message, options = {})
        unless ENV["GUARD_GEM_SILENCE_DEPRECATIONS"] == "1"
          backtrace = Thread.current.backtrace[1..5].join("\n\t >")
          msg = format("%s\nDeprecation backtrace: %s", message, backtrace)
          warning(msg, options)
        end
      end

      # Show a debug message that is prefixed with DEBUG and a timestamp.
      #
      # @param [String] message the message to show
      # @option options [Boolean] reset whether to clean the output before
      # @option options [String] plugin manually define the calling plugin
      #
      def debug(message, options = {})
        _filtered_logger_message(message, :debug, :yellow, options)
      end

      # Reset a line.
      #
      def reset_line
        $stderr.print(color_enabled? ? "\r\e[0m" : "\r\n")
      end

      # Clear the output if clearable.
      #
      def clear(opts = {})
        return unless Guard.state.session.clear?

        fail "UI not set up!" if @clearable.nil?
        return unless @clearable || opts[:force]

        @clearable = false
        Terminal.clear
      rescue Errno::ENOENT => e
        warning("Failed to clear the screen: #{e.inspect}")
      end

      # TODO: arguments: UI uses Guard::options anyway
      # @private api
      def reset_and_clear
        @clearable = false
        clear(force: true)
      end

      # Allow the screen to be cleared again.
      #
      def clearable
        @clearable = true
      end

      # Show a scoped action message.
      #
      # @param [String] action the action to show
      # @param [Hash] scope hash with a guard or a group scope
      #
      def action_with_scopes(action, scope)
        titles = Guard.state.scope.titles(scope)
        info "#{action} #{titles.join(', ')}"
      end

      private

      # Filters log messages depending on either the
      # `:only`` or `:except` option.
      #
      # @param [String] plugin the calling plugin name
      # @yield When the message should be logged
      # @yieldparam [String] param the calling plugin name
      #
      def _filter(plugin)
        only = options.only
        except = options.except
        plugin ||= _calling_plugin_name

        match = !(only || except)
        match ||= (only && only.match(plugin))
        match ||= (except && !except.match(plugin))
        return unless match
        yield plugin
      end

      # @private
      def _filtered_logger_message(message, method, color_name, options = {})
        message = color(message, color_name) if color_name

        _filter(options[:plugin]) do
          reset_line if options[:reset]
          logger.send(method, message)
        end
      end

      # Tries to extract the calling Guard plugin name
      # from the call stack.
      #
      # @param [Integer] depth the stack depth
      # @return [String] the Guard plugin name
      #
      def _calling_plugin_name
        name = caller.lazy.map do |line|
          %r{(?<!guard\/lib)\/(guard\/[a-z_]*)(/[a-z_]*)?.rb:}i.match(line)
        end.reject(&:nil?).take(1).force.first
        return "Guard" unless name || (name && name[1] == "guard/lib")
        name[1].split("/").map do |part|
          part.split(/[^a-z0-9]/i).map(&:capitalize).join
        end.join("::")
      end

      # Checks if color output can be enabled.
      #
      # @return [Boolean] whether color is enabled or not
      #
      def color_enabled?
        @color_enabled_initialized ||= false
        @color_enabled = nil unless @color_enabled_initialized
        @color_enabled_initialized = true
        return @color_enabled unless @color_enabled.nil?
        return (@color_enabled = true) unless Gem.win_platform?
        return (@color_enabled = true) if ENV["ANSICON"]

        @color_enabled =
          begin
            require "rubygems" unless ENV["NO_RUBYGEMS"]
            require "Win32/Console/ANSI"
            true
          rescue LoadError
            info "Run 'gem install win32console' to use color on Windows"
            false
          end
      end

      # Colorizes a text message. See the constant in the UI class for possible
      # color_options parameters. You can pass optionally :bright, a foreground
      # color and a background color.
      #
      # @example
      #
      #   color('Hello World', :red, :bright)
      #
      # @param [String] text the text to colorize
      # @param [Array] color_options the color options
      #
      def color(text, *color_options)
        color_code = ""
        color_options.each do |color_option|
          color_option = color_option.to_s
          next if color_option == ""

          unless color_option =~ /\d+/
            color_option = const_get("ANSI_ESCAPE_#{ color_option.upcase }")
          end
          color_code += ";" + color_option
        end
        color_enabled? ? "\e[0#{ color_code }m#{ text }\e[0m" : text
      end
    end
  end
end
