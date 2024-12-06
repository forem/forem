# frozen_string_literal: true

module I18n::Tasks
  module Command
    module DSL
      def self.included(base)
        base.module_eval do
          @dsl = Hash.new { |h, k| h[k] = {} }
          extend ClassMethods
        end
      end

      def t(*args, **kwargs)
        I18n.t(*args, **kwargs)
      end

      module ClassMethods
        def cmd(name, conf = nil)
          if conf
            conf        = conf.dup
            conf[:args] = (conf[:args] || []).map { |arg| arg.is_a?(Symbol) ? arg(arg) : arg }
            dsl(:cmds)[name] = conf
          else
            dsl(:cmds)[name]
          end
        end

        def arg(ref, *args)
          if args.present?
            dsl(:args)[ref] = args
          else
            dsl(:args)[ref]
          end
        end

        def cmds
          dsl(:cmds)
        end

        def dsl(key)
          @dsl[key]
        end

        # late-bound I18n.t for module bodies
        def t(*args, **kwargs)
          proc { I18n.t(*args, **kwargs) }
        end

        # if class is a module, merge DSL definitions when it is included
        def included(base)
          base.instance_variable_get(:@dsl).deep_merge!(@dsl)
        end
      end
    end
  end
end
