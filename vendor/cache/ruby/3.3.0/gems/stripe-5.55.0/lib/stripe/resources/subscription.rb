# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class Subscription < APIResource
    extend Stripe::APIOperations::Create
    include Stripe::APIOperations::Delete
    extend Stripe::APIOperations::List
    extend Stripe::APIOperations::Search
    include Stripe::APIOperations::Save

    OBJECT_NAME = "subscription"

    custom_method :delete_discount, http_verb: :delete, http_path: "discount"

    def delete_discount(params = {}, opts = {})
      request_stripe_object(
        method: :delete,
        path: resource_url + "/discount",
        params: params,
        opts: opts
      )
    end

    save_nested_resource :source

    def self.search(params = {}, opts = {})
      _search("/v1/subscriptions/search", params, opts)
    end

    def self.search_auto_paging_each(params = {}, opts = {}, &blk)
      search(params, opts).auto_paging_each(&blk)
    end
  end
end
