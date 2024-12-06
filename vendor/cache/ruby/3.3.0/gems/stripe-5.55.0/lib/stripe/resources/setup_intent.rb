# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class SetupIntent < APIResource
    extend Stripe::APIOperations::Create
    extend Stripe::APIOperations::List
    include Stripe::APIOperations::Save

    OBJECT_NAME = "setup_intent"

    custom_method :cancel, http_verb: :post
    custom_method :confirm, http_verb: :post
    custom_method :verify_microdeposits, http_verb: :post

    def cancel(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: resource_url + "/cancel",
        params: params,
        opts: opts
      )
    end

    def confirm(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: resource_url + "/confirm",
        params: params,
        opts: opts
      )
    end

    def verify_microdeposits(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: resource_url + "/verify_microdeposits",
        params: params,
        opts: opts
      )
    end
  end
end
