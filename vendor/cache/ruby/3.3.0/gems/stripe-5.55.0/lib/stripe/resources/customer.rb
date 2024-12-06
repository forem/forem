# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class Customer < APIResource
    extend Stripe::APIOperations::Create
    include Stripe::APIOperations::Delete
    extend Stripe::APIOperations::List
    extend Stripe::APIOperations::Search
    include Stripe::APIOperations::Save
    extend Stripe::APIOperations::NestedResource

    OBJECT_NAME = "customer"

    custom_method :create_funding_instructions, http_verb: :post, http_path: "funding_instructions"
    custom_method :list_payment_methods, http_verb: :get, http_path: "payment_methods"

    nested_resource_class_methods :cash_balance,
                                  operations: %i[retrieve update],
                                  resource_plural: "cash_balance"
    nested_resource_class_methods :balance_transaction,
                                  operations: %i[create retrieve update list]
    nested_resource_class_methods :tax_id,
                                  operations: %i[create retrieve delete list]

    def create_funding_instructions(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: resource_url + "/funding_instructions",
        params: params,
        opts: opts
      )
    end

    def list_payment_methods(params = {}, opts = {})
      request_stripe_object(
        method: :get,
        path: resource_url + "/payment_methods",
        params: params,
        opts: opts
      )
    end

    custom_method :delete_discount, http_verb: :delete, http_path: "discount"

    save_nested_resource :source
    nested_resource_class_methods :source,
                                  operations: %i[create retrieve update delete list]

    # The API request for deleting a card or bank account and for detaching a
    # source object are the same.
    class << self
      alias detach_source delete_source
    end

    # Deletes a discount associated with the customer.
    #
    # Returns the deleted discount. The customer object is not updated,
    # so you must call `refresh` on it to get a new version with the
    # discount removed.
    def delete_discount
      resp, opts = execute_resource_request(:delete, resource_url + "/discount")
      Util.convert_to_stripe_object(resp.data, opts)
    end

    def self.search(params = {}, opts = {})
      _search("/v1/customers/search", params, opts)
    end

    def self.search_auto_paging_each(params = {}, opts = {}, &blk)
      search(params, opts).auto_paging_each(&blk)
    end
  end
end
