# frozen_string_literal: true

module RubyNext
  module Language
    module Rewriters
      class NumberedParams < Base
        using RubyNext

        NAME = "numbered-params"
        SYNTAX_PROBE = "proc { _1 }.call(1)"
        MIN_SUPPORTED_VERSION = Gem::Version.new("2.7.0")

        def on_numblock(node)
          context.track! self

          proc_or_lambda, num, body = *node.children

          if proc_or_lambda.type == :lambda
            insert_before(node.loc.begin, "(#{proc_args_str(num)})")
          else
            insert_after(node.loc.begin, " |#{proc_args_str(num)}|")
          end

          node.updated(
            :block,
            [
              proc_or_lambda,
              proc_args(num),
              body
            ]
          )
        end

        private

        def proc_args_str(n)
          (1..n).map { |numero| "_#{numero}" }.join(", ")
        end

        def proc_args(n)
          return s(:args, s(:procarg0, s(:arg, :_1))) if n == 1

          (1..n).map do |numero|
            s(:arg, :"_#{numero}")
          end.then do |args|
            s(:args, *args)
          end
        end
      end
    end
  end
end
