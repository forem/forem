require 'naught/null_class_builder/command'

module Naught
  class NullClassBuilder
    module Commands
      class DefineImplicitConversions < ::Naught::NullClassBuilder::Command
        def call
          defer do |subject|
            subject.module_eval do
              def to_ary
                []
              end

              def to_hash
                {}
              end

              def to_int
                0
              end

              def to_str
                ''
              end
            end
          end
        end
      end
    end
  end
end
