require 'generators/rspec/integration/integration_generator'

module Rspec
  module Generators
    # @private
    class RequestGenerator < IntegrationGenerator
      source_paths << File.expand_path('../integration/templates', __dir__)
    end
  end
end
