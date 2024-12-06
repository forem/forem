# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class PaymentLink < APIResource
    extend Stripe::APIOperations::Create
    extend Stripe::APIOperations::List
    include Stripe::APIOperations::Save

    OBJECT_NAME = "payment_link"

    custom_method :list_line_items, http_verb: :get, http_path: "line_items"

    def list_line_items(params = {}, opts = {})
      request_stripe_object(
        method: :get,
        path: resource_url + "/line_items",
        params: params,
        opts: opts
      )
    end
  end
end
