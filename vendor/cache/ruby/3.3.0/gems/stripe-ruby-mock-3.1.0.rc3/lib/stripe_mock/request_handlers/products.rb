module StripeMock
  module RequestHandlers
    module Products
      def self.included(base)
        base.add_handler 'post /v1/products',        :create_product
        base.add_handler 'get /v1/products/(.*)',    :retrieve_product
        base.add_handler 'post /v1/products/(.*)',   :update_product
        base.add_handler 'get /v1/products',         :list_products
        base.add_handler 'delete /v1/products/(.*)', :destroy_product
      end

      def create_product(_route, _method_url, params, _headers)
        params[:id] ||= new_id('prod')
        validate_create_product_params(params)
        products[params[:id]] = Data.mock_product(params)
      end

      def retrieve_product(route, method_url, _params, _headers)
        id = method_url.match(route).captures.first
        assert_existence :product, id, products[id]
      end

      def update_product(route, method_url, params, _headers)
        id = method_url.match(route).captures.first
        product = assert_existence :product, id, products[id]

        product.merge!(params)
      end

      def list_products(_route, _method_url, params, _headers)
        limit = params[:limit] || 10
        Data.mock_list_object(products.values.take(limit), params)
      end

      def destroy_product(route, method_url, _params, _headers)
        id = method_url.match(route).captures.first
        assert_existence :product, id, products[id]

        products.delete(id)
        { id: id, object: 'product', deleted: true }
      end
    end
  end
end
