# frozen_string_literals: true

module Lumberjack
  # This class controls the conversion of log entry messages into a loggable format. This allows you
  # to log any object you want and have the logging system deal with converting it into a string.
  #
  # Formats are added to a Formatter by associating them with a class using the +add+ method. Formats
  # are any object that responds to the +call+ method.
  #
  # By default, all object will be converted to strings using their inspect method except for Strings
  # and Exceptions. Strings are not converted and Exceptions are converted using the ExceptionFormatter.
  #
  # Enumerable objects (including Hash and Array) will call the formatter recursively for each element.
  class Formatter
    require_relative "formatter/date_time_formatter"
    require_relative "formatter/exception_formatter"
    require_relative "formatter/id_formatter"
    require_relative "formatter/inspect_formatter"
    require_relative "formatter/object_formatter"
    require_relative "formatter/pretty_print_formatter"
    require_relative "formatter/string_formatter"
    require_relative "formatter/strip_formatter"
    require_relative "formatter/structured_formatter"
    require_relative "formatter/truncate_formatter"

    class << self
      # Returns a new empty formatter with no mapping. For historical reasons, a formatter
      # is initialized with mappings to help output objects as strings. This will return one
      # without the default mappings.
      #
      # @return [Lumberjack::Formatter] a new empty formatter
      def empty
        new.clear
      end
    end

    def initialize
      @class_formatters = {}
      @module_formatters = {}
      structured_formatter = StructuredFormatter.new(self)
      add([String, Numeric, TrueClass, FalseClass], :object)
      add(Object, InspectFormatter.new)
      add(Exception, :exception)
      add(Enumerable, structured_formatter)
    end

    # Add a formatter for a class. The formatter can be specified as either an object
    # that responds to the +call+ method or as a symbol representing one of the predefined
    # formatters, or as a block to the method call.
    #
    # The predefined formatters are:
    #   - :date_time
    #   - :exception
    #   - :id
    #   - :inspect
    #   - :object
    #   - :pretty_print
    #   - :string
    #   - :strip
    #   - :structured
    #   - :truncate
    #
    # You can add multiple classes at once by passing an array of classes.
    #
    # You can also pass class names as strings instead of the classes themselves. This can
    # help avoid loading dependency issues. This applies only to classes; modules cannot be
    # passed in as strings.
    #
    # @param [Class, Module, String, Array<Class, Module, String>] klass The class or module to add a formatter for.
    # @param [Symbol, Class, String, #call] formatter The formatter to use for the class.
    #   If a symbol is passed in, it will be used to load one of the predefined formatters.
    #   If a class is passed in, it will be initialized with the args passed in.
    #   Otherwise, the object will be used as the formatter and must respond to call method.
    # @param [Array] args Arguments to pass to the formatter when it is initialized.
    # @yield [obj] A block that will be used as the formatter for the class.
    # @yieldparam [Object] obj The object to format.
    # @yieldreturn [String] The formatted string.
    # @return [self] Returns itself so that add statements can be chained together.
    #
    # @example
    #
    #   # Use a predefined formatter
    #   formatter.add(MyClass, :pretty_print)
    #
    #   # Pass in a formatter object
    #   formatter.add(MyClass, Lumberjack::Formatter::PrettyPrintFormatter.new)
    #
    #   # Use a block
    #   formatter.add(MyClass){|obj| obj.humanize}
    #
    #   # Add statements can be chained together
    #   formatter.add(MyClass, :pretty_print).add(YourClass){|obj| obj.humanize}
    def add(klass, formatter = nil, *args, &block)
      formatter ||= block
      if formatter.nil?
        remove(klass)
      else
        formatter_class_name = nil
        if formatter.is_a?(Symbol)
          formatter_class_name = "#{formatter.to_s.gsub(/(^|_)([a-z])/) { |m| $~[2].upcase }}Formatter"
        elsif formatter.is_a?(String)
          formatter_class_name = formatter
        end
        if formatter_class_name
          formatter = Formatter.const_get(formatter_class_name)
        end

        if formatter.is_a?(Class)
          formatter = formatter.new(*args)
        end

        Array(klass).each do |k|
          if k.instance_of?(Module)
            @module_formatters[k] = formatter
          else
            k = k.name if k.is_a?(Class)
            @class_formatters[k] = formatter
          end
        end
      end
      self
    end

    # Remove the formatter associated with a class. Remove statements can be chained together.
    #
    # You can remove multiple classes at once by passing an array of classes.
    #
    # You can also pass class names as strings instead of the classes themselves. This can
    # help avoid loading dependency issues. This applies only to classes; modules cannot be
    # passed in as strings.
    #
    # @param [Class, Module, String, Array<Class, Module, String>] klass The class or module to remove the formatters for.
    # @return [self] Returns itself so that remove statements can be chained together.
    def remove(klass)
      Array(klass).each do |k|
        if k.instance_of?(Module)
          @module_formatters.delete(k)
        else
          k = k.name if k.is_a?(Class)
          @class_formatters.delete(k)
        end
      end
      self
    end

    # Remove all formatters including the default formatter. Can be chained to add method calls.
    #
    # @return [self] Returns itself so that clear statements can be chained together.
    def clear
      @class_formatters.clear
      @module_formatters.clear
      self
    end

    # Format a message object by applying all formatters attached to it.
    #
    # @param [Object] message The message object to format.
    # @return [Object] The formatted object.
    def format(message)
      formatter = formatter_for(message.class)
      if formatter&.respond_to?(:call)
        formatter.call(message)
      else
        message
      end
    end

    # Compatibility with the Logger::Formatter signature. This method will just convert the message
    # object to a string and ignores the other parameters.
    #
    # @param [Integer, String, Symbol] severity The severity of the message.
    # @param [Time] timestamp The time the message was logged.
    # @param [String] progname The name of the program logging the message.
    # @param [Object] msg The message object to format.
    def call(severity, timestamp, progname, msg)
      "#{format(msg)}#{Lumberjack::LINE_SEPARATOR}"
    end

    private

    # Find the formatter for a class by looking it up using the class hierarchy.
    def formatter_for(klass) # :nodoc:
      check_modules = true
      until klass.nil?
        formatter = @class_formatters[klass.name]
        return formatter if formatter

        if check_modules
          _, formatter = @module_formatters.detect { |mod, f| klass.include?(mod) }
          check_modules = false
          return formatter if formatter
        end

        klass = klass.superclass
      end
    end
  end
end
