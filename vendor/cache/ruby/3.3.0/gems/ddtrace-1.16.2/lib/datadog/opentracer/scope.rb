# frozen_string_literal: true

module Datadog
  module OpenTracer
    # OpenTracing adapter for scope
    # @public_api
    class Scope < ::OpenTracing::Scope
      attr_reader \
        :manager,
        :span

      def initialize(manager:, span:)
        @manager = manager
        @span = span
      end
    end
  end
end
