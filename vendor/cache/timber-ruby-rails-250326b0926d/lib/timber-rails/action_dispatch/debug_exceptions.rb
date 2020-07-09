module Timber
  module Integrations
    module ActionDispatch
      # Reponsible for disabled logging in the ActionDispatch::DebugExceptions
      # Rack middleware. We cannot simply remove the middleware because it is
      # coupled with displaying an exception debug screen if debug exceptions is enabled.
      #
      # @private
      class DebugExceptions < Integrator

        # Patch for disabling logging
        #
        # @private
        module InstanceMethods
          def self.included(klass)
            klass.class_eval do
              private
                def logger(*args)
                  nil
                end
            end
          end
        end

        def initialize
          begin
            # Rails >= 3.1
            require "action_dispatch/middleware/debug_exceptions"
          rescue LoadError
            # Rails < 3.1
            require "action_dispatch/middleware/show_exceptions"
          end
        rescue LoadError => e
          raise RequirementNotMetError.new(e.message)
        end

        def integrate!
          if defined?(::ActionDispatch::DebugExceptions) && !::ActionDispatch::DebugExceptions.include?(InstanceMethods)
            ::ActionDispatch::DebugExceptions.send(:include, InstanceMethods)
          end

          if defined?(::ActionDispatch::ShowExceptions) && !::ActionDispatch::ShowExceptions.include?(InstanceMethods)
            ::ActionDispatch::ShowExceptions.send(:include, InstanceMethods)
          end

          true
        end
      end
    end
  end
end
