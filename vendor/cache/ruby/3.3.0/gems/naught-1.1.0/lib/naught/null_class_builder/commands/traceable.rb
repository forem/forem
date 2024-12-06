require 'naught/null_class_builder/command'

module Naught
  class NullClassBuilder
    module Commands
      class Traceable < Naught::NullClassBuilder::Command
        def call
          defer do |subject|
            subject.module_eval do
              attr_reader :__file__, :__line__

              def initialize(options = {})
                range = (RUBY_VERSION.to_f == 1.9 && RUBY_PLATFORM != 'java') ? 4 : 3
                backtrace = options.fetch(:caller) { Kernel.caller(range) }
                @__file__, line = backtrace[0].split(':')
                @__line__ = line.to_i
              end
            end
          end
        end
      end
    end
  end
end
