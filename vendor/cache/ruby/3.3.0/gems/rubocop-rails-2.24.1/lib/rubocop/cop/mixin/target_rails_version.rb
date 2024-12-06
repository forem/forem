# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for checking target rails version.
    module TargetRailsVersion
      def minimum_target_rails_version(version)
        @minimum_target_rails_version = version
      end

      def support_target_rails_version?(version)
        @minimum_target_rails_version <= version
      end
    end
  end
end
