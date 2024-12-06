require 'generators/rspec'
require 'rspec/core/warnings'

module Rspec
  module Generators
    # @private
    class IntegrationGenerator < Base
      class_option :request_specs,
                   type: :boolean,
                   default: true,
                   desc: "Generate request specs"

      source_paths << File.expand_path('../request/templates', __dir__)

      def generate_request_spec
        return unless options[:request_specs]

        RSpec.warn_deprecation <<-WARNING.gsub(/\s*\|/, ' ')
          |The integration generator is deprecated
          |and will be deleted in RSpec-Rails 7.
          |Please use the request generator instead.
        WARNING

        template 'request_spec.rb',
                 target_path('requests', "#{name.underscore.pluralize}_spec.rb")
      end
    end
  end
end
