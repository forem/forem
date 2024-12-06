module BetterErrors
  module REPL
    class Basic
      def initialize(binding, _exception)
        @binding = binding
      end

      def send_input(str)
        [execute(str), ">>", ""]
      end

    private
      def execute(str)
        "=> #{@binding.eval(str).inspect}\n"
      rescue Exception => e
        "!! #{e.inspect rescue e.class.to_s rescue "Exception"}\n"
      end
    end
  end
end
