# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module FinancialConnections
    class Account < APIResource
      OBJECT_NAME = "financial_connections.account"

      custom_method :disconnect, http_verb: :post
      custom_method :refresh, http_verb: :post

      def disconnect(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: resource_url + "/disconnect",
          params: params,
          opts: opts
        )
      end

      def refresh(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: resource_url + "/refresh",
          params: params,
          opts: opts
        )
      end
    end
  end
end
