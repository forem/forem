# frozen_string_literal: true

require "datadog/core/configuration/settings"
require "datadog/core/configuration/components"

require_relative "configuration/settings"
require_relative "configuration/components"

module Datadog
  module CI
    # Extends Datadog tracing with CI features
    module Extensions
      def self.activate!
        Core::Configuration::Settings.extend(CI::Configuration::Settings)
        Core::Configuration::Components.prepend(CI::Configuration::Components)
      end
    end
  end
end
