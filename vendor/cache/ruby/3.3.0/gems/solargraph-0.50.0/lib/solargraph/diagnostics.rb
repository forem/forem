# frozen_string_literal: true

module Solargraph
  # The Diagnostics library provides reporters for analyzing problems in code
  # and providing the results to language server clients.
  #
  module Diagnostics
    autoload :Base,            'solargraph/diagnostics/base'
    autoload :Severities,      'solargraph/diagnostics/severities'
    autoload :Rubocop,         'solargraph/diagnostics/rubocop'
    autoload :RubocopHelpers,  'solargraph/diagnostics/rubocop_helpers'
    autoload :RequireNotFound, 'solargraph/diagnostics/require_not_found'
    autoload :UpdateErrors,    'solargraph/diagnostics/update_errors'
    autoload :TypeCheck,       'solargraph/diagnostics/type_check'

    class << self
      # Add a reporter with a name to identify it in .solargraph.yml files.
      #
      # @param name [String] The name
      # @param klass [Class<Solargraph::Diagnostics::Base>] The class implementation
      # @return [void]
      def register name, klass
        reporter_hash[name] = klass
      end

      # Get an array of reporter names.
      #
      # @return [Array<String>]
      def reporters
        reporter_hash.keys - ['type_not_defined'] # @todo Hide type_not_defined for now
      end

      # Find a reporter by name.
      #
      # @param name [String] The name with which the reporter was registered
      # @return [Class<Solargraph::Diagnostics::Base>]
      def reporter name
        reporter_hash[name]
      end

      private

      # @return [Hash]
      def reporter_hash
        @reporter_hash ||= {}
      end
    end

    register 'rubocop', Rubocop
    register 'require_not_found', RequireNotFound
    register 'typecheck', TypeCheck
    register 'update_errors', UpdateErrors
    register 'type_not_defined', TypeCheck # @todo Retained for backwards compatibility
  end
end
