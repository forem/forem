# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class Source < APIResource
    extend Stripe::APIOperations::Create
    include Stripe::APIOperations::Save
    extend Stripe::APIOperations::NestedResource

    OBJECT_NAME = "source"

    custom_method :verify, http_verb: :post

    nested_resource_class_methods :source_transaction,
                                  operations: %i[retrieve list]

    def verify(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: resource_url + "/verify",
        params: params,
        opts: opts
      )
    end

    def detach(params = {}, opts = {})
      if !respond_to?(:customer) || customer.nil? || customer.empty?
        raise NotImplementedError,
              "This source object does not appear to be currently attached " \
              "to a customer object."
      end

      url = "#{Customer.resource_url}/#{CGI.escape(customer)}/sources" \
            "/#{CGI.escape(id)}"
      resp, opts = execute_resource_request(:delete, url, params, opts)
      initialize_from(resp.data, opts)
    end

    def source_transactions(params = {}, opts = {})
      resp, opts = execute_resource_request(:get, resource_url + "/source_transactions", params,
                                            opts)
      Util.convert_to_stripe_object(resp.data, opts)
    end
    extend Gem::Deprecate
    deprecate :source_transactions, :"Source.list_source_transactions", 2020, 1
  end
end
