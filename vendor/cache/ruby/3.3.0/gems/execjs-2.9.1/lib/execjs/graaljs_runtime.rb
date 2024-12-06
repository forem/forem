require "execjs/runtime"

module ExecJS
  class GraalJSRuntime < Runtime
    class Context < Runtime::Context
      def initialize(runtime, source = "", options = {})
        @context = Polyglot::InnerContext.new
        @context.eval('js', 'delete this.console')
        @js_object = @context.eval('js', 'Object')

        source = source.encode(Encoding::UTF_8)
        unless source.empty?
          translate do
            eval_in_context(source)
          end
        end
      end

      def exec(source, options = {})
        source = source.encode(Encoding::UTF_8)
        source = "(function(){#{source}})()" if /\S/.match?(source)

        translate do
          eval_in_context(source)
        end
      end

      def eval(source, options = {})
        source = source.encode(Encoding::UTF_8)
        source = "(#{source})" if /\S/.match?(source)

        translate do
          eval_in_context(source)
        end
      end

      def call(source, *args)
        source = source.encode(Encoding::UTF_8)
        source = "(#{source})" if /\S/.match?(source)

        translate do
          function = eval_in_context(source)
          function.call(*convert_ruby_to_js(args))
        end
      end

      private

      ForeignException = defined?(Polyglot::ForeignException) ? Polyglot::ForeignException : ::RuntimeError

      def translate
        convert_js_to_ruby yield
      rescue ForeignException => e
        if e.message && e.message.start_with?('SyntaxError:')
          error_class = ExecJS::RuntimeError
        else
          error_class = ExecJS::ProgramError
        end

        backtrace = (e.backtrace || []).map { |line| line.sub('(eval)', '(execjs)') }
        raise error_class, e.message, backtrace
      end

      def convert_js_to_ruby(value)
        case value
        when true, false, Integer, Float
          value
        else
          if value.nil?
            nil
          elsif value.respond_to?(:call)
            nil
          elsif value.respond_to?(:to_str)
            value.to_str
          elsif value.respond_to?(:to_ary)
            value.to_ary.map do |e|
              if e.respond_to?(:call)
                nil
              else
                convert_js_to_ruby(e)
              end
            end
          else
            object = value
            h = {}
            object.instance_variables.each do |member|
              v = object[member]
              unless v.respond_to?(:call)
                h[member.to_s] = convert_js_to_ruby(v)
              end
            end
            h
          end
        end
      end

      def convert_ruby_to_js(value)
        case value
        when nil, true, false, Integer, Float
          value
        when String, Symbol
          Truffle::Interop.as_truffle_string value
        when Array
          value.map { |e| convert_ruby_to_js(e) }
        when Hash
          h = @js_object.new
          value.each_pair do |k,v|
            h[convert_ruby_to_js(k)] = convert_ruby_to_js(v)
          end
          h
        else
          raise TypeError, "Unknown how to convert to JS: #{value.inspect}"
        end
      end

      class_eval <<-'RUBY', "(execjs)", 1
        def eval_in_context(code); @context.eval('js', code); end
      RUBY
    end

    def name
      "GraalVM (Graal.js)"
    end

    def available?
      return @available if defined?(@available)

      unless RUBY_ENGINE == "truffleruby"
        return @available = false
      end

      unless defined?(Polyglot::InnerContext)
        warn "TruffleRuby #{RUBY_ENGINE_VERSION} does not have support for inner contexts, use a more recent version", uplevel: 0 if $VERBOSE
        return @available = false
      end

      unless Polyglot.languages.include? "js"
        warn "The language 'js' is not available, you likely need to `export TRUFFLERUBYOPT='--jvm --polyglot'`", uplevel: 0 if $VERBOSE
        warn "You also need to install the 'js' component with 'gu install js' on GraalVM 22.2+", uplevel: 0 if $VERBOSE
        warn "Note that you need TruffleRuby+GraalVM and not just the TruffleRuby standalone to use #{self.class}", uplevel: 0 if $VERBOSE
        return @available = false
      end

      @available = true
    end
  end
end
