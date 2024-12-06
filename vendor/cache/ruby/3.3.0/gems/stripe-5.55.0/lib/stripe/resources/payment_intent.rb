# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class PaymentIntent < APIResource
    extend Stripe::APIOperations::Create
    extend Stripe::APIOperations::List
    extend Stripe::APIOperations::Search
    include Stripe::APIOperations::Save

    OBJECT_NAME = "payment_intent"

    custom_method :apply_customer_balance, http_verb: :post
    custom_method :cancel, http_verb: :post
    custom_method :capture, http_verb: :post
    custom_method :confirm, http_verb: :post
    custom_method :increment_authorization, http_verb: :post
    custom_method :verify_microdeposits, http_verb: :post

    def apply_customer_balance(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: resource_url + "/apply_customer_balance",
        params: params,
        opts: opts
      )
    end

    def cancel(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: resource_url + "/cancel",
        params: params,
        opts: opts
      )
    end

    def capture(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: resource_url + "/capture",
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

    def increment_authorization(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: resource_url + "/increment_authorization",
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

    def self.search(params = {}, opts = {})
      _search("/v1/payment_intents/search", params, opts)
    end

    def self.search_auto_paging_each(params = {}, opts = {}, &blk)
      search(params, opts).auto_paging_each(&blk)
    end
  end
end
