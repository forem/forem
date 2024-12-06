require 'forwardable'
require 'naught/null_class_builder/command'

module Naught
  class NullClassBuilder
    module Commands
      class DefineExplicitConversions < ::Naught::NullClassBuilder::Command
        def call
          defer do |subject|
            subject.module_eval do
              extend Forwardable
              def_delegators :nil, :to_a, :to_c, :to_f, :to_h, :to_i, :to_r, :to_s
            end
          end
        end
      end
    end
  end
end
