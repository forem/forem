# frozen_string_literal: true

require_relative '../../core/configuration/agent_settings_resolver'

module Datadog
  module Tracing
    module Configuration
      # This class encapsulates any tracing specific agent settings
      class AgentSettingsResolver < Datadog::Core::Configuration::AgentSettingsResolver
      end
    end
  end
end
