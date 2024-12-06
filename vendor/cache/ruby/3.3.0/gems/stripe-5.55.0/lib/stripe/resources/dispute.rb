# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class Dispute < APIResource
    extend Stripe::APIOperations::List
    include Stripe::APIOperations::Save

    OBJECT_NAME = "dispute"

    custom_method :close, http_verb: :post

    def close(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: resource_url + "/close",
        params: params,
        opts: opts
      )
    end
  end
end
