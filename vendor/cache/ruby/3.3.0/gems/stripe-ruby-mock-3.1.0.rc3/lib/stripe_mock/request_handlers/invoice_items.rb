module StripeMock
  module RequestHandlers
    module InvoiceItems

      def InvoiceItems.included(klass)
        klass.add_handler 'post /v1/invoiceitems',        :new_invoice_item
        klass.add_handler 'post /v1/invoiceitems/(.*)',   :update_invoice_item
        klass.add_handler 'get /v1/invoiceitems/(.*)',    :get_invoice_item
        klass.add_handler 'get /v1/invoiceitems',         :list_invoice_items
        klass.add_handler 'delete /v1/invoiceitems/(.*)', :delete_invoice_item
      end

      def new_invoice_item(route, method_url, params, headers)
        params[:id] ||= new_id('ii')
        invoice_items[params[:id]] = Data.mock_invoice_item(params)
      end

      def update_invoice_item(route, method_url, params, headers)
        route =~ method_url
        list_item = assert_existence :list_item, $1, invoice_items[$1]
        list_item.merge!(params)
      end

      def delete_invoice_item(route, method_url, params, headers)
        route =~ method_url
        assert_existence :list_item, $1, invoice_items[$1]

        invoice_items[$1] = {
          id: invoice_items[$1][:id],
          deleted: true
        }
      end

      def list_invoice_items(route, method_url, params, headers)
        Data.mock_list_object(invoice_items.values, params)
      end

      def get_invoice_item(route, method_url, params, headers)
        route =~ method_url
        assert_existence :invoice_item, $1, invoice_items[$1]
      end

    end
  end
end
