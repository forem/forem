# frozen_string_literal: true

module RubyNext
  module Language
    module KernelEval
      if Utils.refine_modules?
        refine Kernel do
          def eval(source, bind = nil, *args)
            new_source = ::RubyNext::Language::Runtime.transform(
              source,
              using: ((((__safe_lvar__ = bind) || true) && (!__safe_lvar__.nil? || nil)) && __safe_lvar__.receiver) == TOPLEVEL_BINDING.receiver || ((((__safe_lvar__ = ((((__safe_lvar__ = bind) || true) && (!__safe_lvar__.nil? || nil)) && __safe_lvar__.receiver)) || true) && (!__safe_lvar__.nil? || nil)) && __safe_lvar__.is_a?(Module))
            )
            RubyNext.debug_source(new_source, "(#{caller_locations(1, 1).first})")
            super new_source, bind, *args
          end
        end
      end
    end

    module InstanceEval # :nodoc:
      refine Object do
        def instance_eval(*args, &block)
          return super(*args, &block) if block

          source = args.shift
          new_source = ::RubyNext::Language::Runtime.transform(source, using: false)
          RubyNext.debug_source(new_source, "(#{caller_locations(1, 1).first})")
          super new_source, *args
        end
      end
    end

    module ClassEval
      refine Module do
        def module_eval(*args, &block)
          return super(*args, &block) if block

          source = args.shift
          new_source = ::RubyNext::Language::Runtime.transform(source, using: false)

          RubyNext.debug_source(new_source, "(#{caller_locations(1, 1).first})")
          super new_source, *args
        end

        def class_eval(*args, &block)
          return super(*args, &block) if block

          source = args.shift
          new_source = ::RubyNext::Language::Runtime.transform(source, using: false)
          RubyNext.debug_source(new_source, "(#{caller_locations(1, 1).first})")
          super new_source, *args
        end
      end
    end

    # Refinements for `eval`-like methods.
    # Transpiling eval is only possible if we do not use local from the binding,
    # because we cannot access the binding of caller (without non-production ready hacks).
    #
    # This module is meant mainly for testing purposes.
    module Eval
      include InstanceEval
      include ClassEval
      include KernelEval
    end
  end
end
