# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Issuing
    class Dispute < APIResource
      extend Stripe::APIOperations::Create
      extend Stripe::APIOperations::List
      include Stripe::APIOperations::Save

      OBJECT_NAME = "issuing.dispute"

      custom_method :submit, http_verb: :post

      def submit(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: resource_url + "/submit",
          params: params,
          opts: opts
        )
      end
    end
  end
end
