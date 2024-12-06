require 'bundler'
require 'shellwords'

module Solargraph
  class ApiMap
    module BundlerMethods
      module_function

      # @param directory [String]
      # @return [Hash]
      def require_from_bundle directory
        begin
          Solargraph.logger.info "Loading gems for bundler/require"
          Documentor.specs_from_bundle(directory)
        rescue BundleNotFoundError => e
          Solargraph.logger.warn e.message
          {}
        end
      end
    end
  end
end
