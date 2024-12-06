# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for checking target ruby version.
    module TargetRubyVersion
      def required_minimum_ruby_version
        @minimum_target_ruby_version
      end

      def minimum_target_ruby_version(version)
        @minimum_target_ruby_version = version
      end

      def support_target_ruby_version?(version)
        required_minimum_ruby_version <= version
      end
    end
  end
end
