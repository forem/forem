module Nenv
  class Environment
    module Dumper
      require 'nenv/environment/dumper/default'

      def self.setup(&callback)
        if callback
          callback
        else
          Default
        end
      end
    end
  end
end
