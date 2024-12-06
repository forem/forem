# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class Invoice < APIResource
    extend Stripe::APIOperations::Create
    include Stripe::APIOperations::Delete
    extend Stripe::APIOperations::List
    extend Stripe::APIOperations::Search
    include Stripe::APIOperations::Save

    OBJECT_NAME = "invoice"

    custom_method :finalize_invoice, http_verb: :post, http_path: "finalize"
    custom_method :mark_uncollectible, http_verb: :post
    custom_method :pay, http_verb: :post
    custom_method :send_invoice, http_verb: :post, http_path: "send"
    custom_method :void_invoice, http_verb: :post, http_path: "void"

    def finalize_invoice(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: resource_url + "/finalize",
        params: params,
        opts: opts
      )
    end

    def mark_uncollectible(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: resource_url + "/mark_uncollectible",
        params: params,
        opts: opts
      )
    end

    def pay(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: resource_url + "/pay",
        params: params,
        opts: opts
      )
    end

    def send_invoice(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: resource_url + "/send",
        params: params,
        opts: opts
      )
    end

    def void_invoice(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: resource_url + "/void",
        params: params,
        opts: opts
      )
    end

    def self.upcoming(params, opts = {})
      resp, opts = execute_resource_request(:get, resource_url + "/upcoming", params, opts)
      Util.convert_to_stripe_object(resp.data, opts)
    end

    def self.list_upcoming_line_items(params, opts = {})
      resp, opts = execute_resource_request(:get, resource_url + "/upcoming/lines", params, opts)
      Util.convert_to_stripe_object(resp.data, opts)
    end

    def self.search(params = {}, opts = {})
      _search("/v1/invoices/search", params, opts)
    end

    def self.search_auto_paging_each(params = {}, opts = {}, &blk)
      search(params, opts).auto_paging_each(&blk)
    end
  end
end
