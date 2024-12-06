module Nenv
  class Environment
    module Loader
      require 'nenv/environment/loader/predicate'
      require 'nenv/environment/loader/default'

      def self.setup(meth, &callback)
        if callback
          callback
        else
          if meth.to_s.end_with? '?'
            Predicate
          else
            Default
          end
        end
      end
    end
  end
end
