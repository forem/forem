# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module TestHelpers
    class TestClock < APIResource
      extend Stripe::APIOperations::Create
      include Stripe::APIOperations::Delete
      extend Stripe::APIOperations::List

      OBJECT_NAME = "test_helpers.test_clock"

      custom_method :advance, http_verb: :post

      def advance(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: resource_url + "/advance",
          params: params,
          opts: opts
        )
      end
    end
  end
end
