# frozen_string_literal: true

module Stripe
  module APIOperations
    module Search
      def _search(search_url, filters = {}, opts = {})
        opts = Util.normalize_opts(opts)

        resp, opts = execute_resource_request(:get, search_url, filters, opts)
        obj = SearchResultObject.construct_from(resp.data, opts)

        # set filters so that we can fetch the same limit and query
        # when accessing the next page
        obj.filters = filters.dup
        obj
      end
    end
  end
end
