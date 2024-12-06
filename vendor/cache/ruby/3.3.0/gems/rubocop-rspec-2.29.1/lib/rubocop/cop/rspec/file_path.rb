# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks that spec file paths are consistent and well-formed.
      #
      # This cop is deprecated.
      # We plan to remove it in the next major version update to 3.0.
      # The migration targets are `RSpec/SpecFilePathSuffix`
      # and `RSpec/SpecFilePathFormat`.
      # If you are using this cop, please plan for migration.
      #
      # By default, this checks that spec file paths are consistent with the
      # test subject and enforces that it reflects the described
      # class/module and its optionally called out method.
      #
      # With the configuration option `IgnoreMethods` the called out method will
      # be ignored when determining the enforced path.
      #
      # With the configuration option `CustomTransform` modules or classes can
      # be specified that should not as usual be transformed from CamelCase to
      # snake_case (e.g. 'RuboCop' => 'rubocop' ).
      #
      # With the configuration option `SpecSuffixOnly` test files will only
      # be checked to ensure they end in '_spec.rb'. This option disables
      # checking for consistency in the test subject or test methods.
      #
      # @example
      #   # bad
      #   whatever_spec.rb         # describe MyClass
      #
      #   # bad
      #   my_class_spec.rb         # describe MyClass, '#method'
      #
      #   # good
      #   my_class_spec.rb         # describe MyClass
      #
      #   # good
      #   my_class_method_spec.rb  # describe MyClass, '#method'
      #
      #   # good
      #   my_class/method_spec.rb  # describe MyClass, '#method'
      #
      # @example when configuration is `IgnoreMethods: true`
      #   # bad
      #   whatever_spec.rb         # describe MyClass
      #
      #   # good
      #   my_class_spec.rb         # describe MyClass
      #
      #   # good
      #   my_class_spec.rb         # describe MyClass, '#method'
      #
      # @example when configuration is `SpecSuffixOnly: true`
      #   # good
      #   whatever_spec.rb         # describe MyClass
      #
      #   # good
      #   my_class_spec.rb         # describe MyClass
      #
      #   # good
      #   my_class_spec.rb         # describe MyClass, '#method'
      #
      class FilePath < Base
        include TopLevelGroup
        include Namespace

        MSG = 'Spec path should end with `%<suffix>s`.'

        # @!method example_group(node)
        def_node_matcher :example_group, <<~PATTERN
          (block
            $(send #rspec? _example_group $_ $...) ...
          )
        PATTERN

        # @!method routing_metadata?(node)
        def_node_search :routing_metadata?, '(pair (sym :type) (sym :routing))'

        def on_top_level_example_group(node)
          return unless top_level_groups.one?

          example_group(node) do |send_node, example_group, arguments|
            ensure_correct_file_path(send_node, example_group, arguments)
          end
        end

        private

        def ensure_correct_file_path(send_node, example_group, arguments)
          pattern = pattern_for(example_group, arguments)
          return if filename_ends_with?(pattern)

          # For the suffix shown in the offense message, modify the regular
          # expression pattern to resemble a glob pattern for clearer error
          # messages.
          offense_suffix = pattern.gsub('.*', '*').sub('[^/]', '')
            .sub('\.', '.')
          add_offense(send_node, message: format(MSG, suffix: offense_suffix))
        end

        def routing_spec?(args)
          args.any?(&method(:routing_metadata?)) || routing_spec_path?
        end

        def pattern_for(example_group, arguments)
          method_name = arguments.first
          if spec_suffix_only? || !example_group.const_type? ||
              routing_spec?(arguments)
            return pattern_for_spec_suffix_only
          end

          [
            expected_path(example_group),
            name_pattern(method_name),
            '[^/]*_spec\.rb'
          ].join
        end

        def pattern_for_spec_suffix_only
          '.*_spec\.rb'
        end

        def name_pattern(method_name)
          return unless method_name&.str_type?
          return if ignore_methods?

          ".*#{method_name.str_content.gsub(/\s/, '_').gsub(/\W/, '')}"
        end

        def expected_path(constant)
          constants = namespace(constant) + constant.const_name.split('::')

          File.join(
            constants.map do |name|
              custom_transform.fetch(name) { camel_to_snake_case(name) }
            end
          )
        end

        def camel_to_snake_case(string)
          string
            .gsub(/([^A-Z])([A-Z]+)/, '\1_\2')
            .gsub(/([A-Z])([A-Z][^A-Z\d]+)/, '\1_\2')
            .downcase
        end

        def custom_transform
          cop_config.fetch('CustomTransform', {})
        end

        def ignore_methods?
          cop_config['IgnoreMethods']
        end

        def filename_ends_with?(pattern)
          expanded_file_path.match?("#{pattern}$")
        end

        def relevant_rubocop_rspec_file?(_file)
          true
        end

        def spec_suffix_only?
          cop_config['SpecSuffixOnly']
        end

        def routing_spec_path?
          expanded_file_path.include?('spec/routing/')
        end

        def expanded_file_path
          File.expand_path(processed_source.file_path)
        end
      end
    end
  end
end
