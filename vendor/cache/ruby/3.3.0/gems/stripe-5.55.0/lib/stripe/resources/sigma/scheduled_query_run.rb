# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Sigma
    class ScheduledQueryRun < APIResource
      extend Stripe::APIOperations::List

      OBJECT_NAME = "scheduled_query_run"

      def self.resource_url
        "/v1/sigma/scheduled_query_runs"
      end
    end
  end
end
