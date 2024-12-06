require 'execjs'
require 'coffee_script/source'

module CoffeeScript
  Error            = ExecJS::Error
  EngineError      = ExecJS::RuntimeError
  CompilationError = ExecJS::ProgramError

  module Source
    def self.path
      @path ||= ENV['COFFEESCRIPT_SOURCE_PATH'] || bundled_path
    end

    def self.path=(path)
      @contents = @version = @bare_option = @context = nil
      @path = path
    end

    COMPILE_FUNCTION_SOURCE = <<-JS
      ;function compile(script, options) {
        try {
          return CoffeeScript.compile(script, options);
        } catch (err) {
          if (err instanceof SyntaxError && err.location) {
            throw new SyntaxError([
              err.filename || "[stdin]",
              err.location.first_line + 1,
              err.location.first_column + 1
            ].join(":") + ": " + err.message)
          } else {
            throw err;
          }
        }
      }
    JS

    def self.contents
      @contents ||= File.read(path) + COMPILE_FUNCTION_SOURCE
    end

    def self.version
      @version ||= contents[/CoffeeScript Compiler v([\d.]+)/, 1]
    end

    def self.bare_option
      @bare_option ||= contents.match(/noWrap/) ? 'noWrap' : 'bare'
    end

    def self.context
      @context ||= ExecJS.compile(contents)
    end
  end

  class << self
    def engine
    end

    def engine=(engine)
    end

    def version
      Source.version
    end

    # Compile a script (String or IO) to JavaScript.
    def compile(script, options = {})
      script = script.read if script.respond_to?(:read)

      if options.key?(:bare)
      elsif options.key?(:no_wrap)
        options[:bare] = options[:no_wrap]
      else
        options[:bare] = false
      end

      # Stringify keys
      options = options.inject({}) { |h, (k, v)| h[k.to_s] = v; h }
      Source.context.call("compile", script, options)
    end
  end
end
