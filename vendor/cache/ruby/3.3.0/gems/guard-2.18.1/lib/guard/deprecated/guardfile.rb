require "guard/config"
fail "Deprecations disabled (strict mode)" if Guard::Config.new.strict?

require "guard/guardfile/generator"

module Guard
  module Deprecated
    module Guardfile
      def self.add_deprecated(dsl_klass)
        dsl_klass.send(:extend, ClassMethods)
      end

      module ClassMethods
        MORE_INFO_ON_UPGRADING_TO_GUARD_2 = <<-EOS.gsub(/^\s*/, "")
          For more information on how to upgrade for Guard 2.0, please head
          over to: https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0%s
        EOS
        # @deprecated Use {Guardfile::Generator#create_guardfile} instead.
        #
        # @see https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0 How to
        # upgrade for Guard 2.0
        #
        CREATE_GUARDFILE = <<-EOS.gsub(/^\s*/, "")
          Starting with Guard 2.0 'Guard::Guardfile.create_guardfile(options)'
          is deprecated.

          Please use 'Guard::Guardfile::Generator.new(options).create_guardfile'
          instead.

          #{MORE_INFO_ON_UPGRADING_TO_GUARD_2 % '#deprecated-methods-2'}
        EOS

        def create_guardfile(options = {})
          UI.deprecation(CREATE_GUARDFILE)
          ::Guard::Guardfile::Generator.new(options).create_guardfile
        end

        # @deprecated Use {Guardfile::Generator#initialize_template} instead.
        #
        # @see https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0 How to
        # upgrade for Guard 2.0
        #
        # Deprecator message for the `Guardfile.initialize_template` method
        INITIALIZE_TEMPLATE = <<-EOS.gsub(/^\s*/, "")
          Starting with Guard 2.0
          'Guard::Guardfile.initialize_template(plugin_name)' is deprecated.

          Please use
          'Guard::Guardfile::Generator.new.initialize_template(plugin_name)'
          instead.

          #{MORE_INFO_ON_UPGRADING_TO_GUARD_2 % '#deprecated-methods-2'}
        EOS

        def initialize_template(plugin_name)
          UI.deprecation(INITIALIZE_TEMPLATE)
          ::Guard::Guardfile::Generator.new.initialize_template(plugin_name)
        end

        # @deprecated Use {Guardfile::Generator#initialize_all_templates}
        # instead.
        #
        # @see https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0 How to
        # upgrade for Guard 2.0
        #
        # Deprecator message for the `Guardfile.initialize_all_templates` method
        INITIALIZE_ALL_TEMPLATES = <<-EOS.gsub(/^\s*/, "")
          Starting with Guard 2.0 'Guard::Guardfile.initialize_all_templates'
          is deprecated.

          Please use 'Guard::Guardfile::Generator.new.initialize_all_templates'
          instead.

          #{MORE_INFO_ON_UPGRADING_TO_GUARD_2 % '#deprecated-methods-2'}
        EOS

        def initialize_all_templates
          UI.deprecation(INITIALIZE_ALL_TEMPLATES)
          ::Guard::Guardfile::Generator.new.initialize_all_templates
        end
      end
    end
  end
end
