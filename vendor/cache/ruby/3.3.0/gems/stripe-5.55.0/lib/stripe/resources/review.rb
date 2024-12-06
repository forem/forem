# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class Review < APIResource
    extend Stripe::APIOperations::List

    OBJECT_NAME = "review"

    custom_method :approve, http_verb: :post

    def approve(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: resource_url + "/approve",
        params: params,
        opts: opts
      )
    end
  end
end
