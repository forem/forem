require 'naught/basic_object'
require 'naught/null_class_builder/command'

module Naught
  class NullClassBuilder
    module Commands
      class Mimic < Naught::NullClassBuilder::Command
        NULL_SINGLETON_CLASS = (class << Object.new; self; end)

        attr_reader :class_to_mimic, :include_super, :singleton_class

        def initialize(builder, class_to_mimic_or_options, options = {})
          super(builder)

          if class_to_mimic_or_options.is_a?(Hash)
            options          = class_to_mimic_or_options.merge(options)
            instance         = options.fetch(:example)
            @singleton_class = (class << instance; self; end)
            @class_to_mimic  = instance.class
          else
            @singleton_class = NULL_SINGLETON_CLASS
            @class_to_mimic  = class_to_mimic_or_options
          end
          @include_super = options.fetch(:include_super) { true }

          builder.base_class   = root_class_of(@class_to_mimic)
          class_to_mimic       = @class_to_mimic
          builder.inspect_proc = lambda { "<null:#{class_to_mimic}>" }
          builder.interface_defined = true
        end

        def call
          defer do |subject|
            methods_to_stub.each do |method_name|
              builder.stub_method(subject, method_name)
            end
          end
        end

      private

        def root_class_of(klass)
          klass.ancestors.include?(Object) ? Object : Naught::BasicObject
        end

        def methods_to_stub
          methods_to_mimic =
            class_to_mimic.instance_methods(include_super) |
            singleton_class.instance_methods(false)
          methods_to_mimic - Object.instance_methods
        end
      end
    end
  end
end
