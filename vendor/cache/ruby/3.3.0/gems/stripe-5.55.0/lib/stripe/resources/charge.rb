# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class Charge < APIResource
    extend Stripe::APIOperations::Create
    extend Stripe::APIOperations::List
    extend Stripe::APIOperations::Search
    include Stripe::APIOperations::Save

    OBJECT_NAME = "charge"

    custom_method :capture, http_verb: :post

    def capture(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: resource_url + "/capture",
        params: params,
        opts: opts
      )
    end

    def self.search(params = {}, opts = {})
      _search("/v1/charges/search", params, opts)
    end

    def self.search_auto_paging_each(params = {}, opts = {}, &blk)
      search(params, opts).auto_paging_each(&blk)
    end
  end
end
