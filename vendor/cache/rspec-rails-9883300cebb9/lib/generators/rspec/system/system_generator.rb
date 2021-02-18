require 'generators/rspec'

if ::Rails::VERSION::STRING >= '5.1'
  module Rspec
    module Generators
      # @private
      class SystemGenerator < Base
        class_option :system_specs, type: :boolean, default: true,  desc: "Generate system specs"

        def generate_system_spec
          return unless options[:system_specs]

          template template_name, File.join('spec/system', class_path, filename)
        end

        def template_name
          'system_spec.rb'
        end

        def filename
          "#{table_name}_spec.rb"
        end
      end
    end
  end
end
