# frozen_string_literal: true

require_relative 'processor'
require_relative 'processor/rule_merger'
require_relative 'processor/rule_loader'
require_relative 'processor/actions'

module Datadog
  module AppSec
    # Core-pluggable component for AppSec
    class Component
      class << self
        def build_appsec_component(settings)
          return unless settings.respond_to?(:appsec) && settings.appsec.enabled

          processor = create_processor(settings)

          # We want to always instrument user events when AppSec is enabled.
          # There could be cases in which users use the DD_APPSEC_ENABLED Env variable to
          # enable AppSec, in that case, Devise is already instrumented.
          # In the case that users do not use DD_APPSEC_ENABLED, we have to instrument it,
          # hence the lines above.
          devise_integration = Datadog::AppSec::Contrib::Devise::Integration.new
          settings.appsec.instrument(:devise) unless devise_integration.patcher.patched?

          new(processor: processor)
        end

        private

        def create_processor(settings)
          rules = AppSec::Processor::RuleLoader.load_rules(ruleset: settings.appsec.ruleset)
          return nil unless rules

          actions = rules['actions']

          AppSec::Processor::Actions.merge(actions) if actions

          data = AppSec::Processor::RuleLoader.load_data(
            ip_denylist: settings.appsec.ip_denylist,
            user_id_denylist: settings.appsec.user_id_denylist
          )

          ruleset = AppSec::Processor::RuleMerger.merge(
            rules: [rules],
            data: data,
          )

          processor = Processor.new(ruleset: ruleset)
          return nil unless processor.ready?

          processor
        end
      end

      attr_reader :processor

      def initialize(processor:)
        @processor = processor
        @mutex = Mutex.new
      end

      def reconfigure(ruleset:, actions:)
        @mutex.synchronize do
          AppSec::Processor::Actions.merge(actions)

          new = Processor.new(ruleset: ruleset)

          if new && new.ready?
            old = @processor
            @processor = new
            old.finalize if old
          end
        end
      end

      def reconfigure_lock(&block)
        @mutex.synchronize(&block)
      end

      def shutdown!
        @mutex.synchronize do
          if processor && processor.ready?
            processor.finalize
            @processor = nil
          end
        end
      end
    end
  end
end
