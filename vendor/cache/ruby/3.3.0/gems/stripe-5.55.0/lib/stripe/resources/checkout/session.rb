# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Checkout
    class Session < APIResource
      extend Stripe::APIOperations::Create
      extend Stripe::APIOperations::List
      extend Stripe::APIOperations::NestedResource

      OBJECT_NAME = "checkout.session"

      custom_method :expire, http_verb: :post

      nested_resource_class_methods :line_item, operations: %i[list]

      def expire(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: resource_url + "/expire",
          params: params,
          opts: opts
        )
      end
    end
  end
end
