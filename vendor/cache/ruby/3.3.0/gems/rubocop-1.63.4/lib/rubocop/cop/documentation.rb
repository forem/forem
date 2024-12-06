# frozen_string_literal: true

module RuboCop
  module Cop
    # Helpers for builtin documentation
    module Documentation
      module_function

      # @api private
      def department_to_basename(department)
        "cops_#{department.to_s.downcase.tr('/', '_')}"
      end

      # @api private
      def url_for(cop_class, config = nil)
        base = department_to_basename(cop_class.department)
        fragment = cop_class.cop_name.downcase.gsub(/[^a-z]/, '')
        base_url = base_url_for(cop_class, config)

        "#{base_url}/#{base}.html##{fragment}"
      end

      # @api private
      def base_url_for(cop_class, config)
        return default_base_url unless config

        department_name = cop_class.department.to_s

        config.for_department(department_name)['DocumentationBaseURL'] ||
          config.for_all_cops['DocumentationBaseURL']
      end

      # @api private
      def default_base_url
        'https://docs.rubocop.org/rubocop'
      end
    end
  end
end
