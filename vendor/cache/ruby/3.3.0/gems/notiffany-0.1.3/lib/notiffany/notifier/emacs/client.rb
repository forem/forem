require 'erb'
module Notiffany
  class Notifier
    class Emacs < Base
      # Handles evaluating ELISP code in Emacs via Erb
      class Client
        attr_reader :elisp_erb

        # Creates a safe binding with local variables for ERB
        class Elisp < ERB
          attr_reader :color
          attr_reader :bgcolor
          attr_reader :message

          def initialize(code, color, bgcolor, message)
            @color = color
            @bgcolor = bgcolor
            @message = message
            @code = code
            super(@code)
          end

          def result
            super(binding)
          end
        end

        def initialize(options)
          @client = options[:client]
          @elisp_erb = options[:elisp_erb]
          raise ArgumentError, 'No :elisp_erb option given!' unless elisp_erb
        end

        def available?
          script = Elisp.new(@elisp_erb, nil, nil, nil).result
          _emacs_eval({ 'ALTERNATE_EDITOR' => 'false' }, script)
        end

        def notify(color, bgcolor, message = nil)
          elisp = Elisp.new(elisp_erb, color, bgcolor, message).result
          _emacs_eval({ 'ALTERNATE_EDITOR' => 'false' }, elisp)
        end

        private

        def _emacs_eval(env, code)
          Shellany::Sheller.run(env, @client, '--eval', code)
        end
      end
    end
  end
end
