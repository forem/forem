module StripeMock
  module RequestHandlers
    module TaxRates
      def TaxRates.included(klass)
        klass.add_handler 'post /v1/tax_rates', :new_tax_rate
        klass.add_handler 'post /v1/tax_rates/([^/]*)', :update_tax_rate
        klass.add_handler 'get /v1/tax_rates/([^/]*)', :get_tax_rate
        klass.add_handler 'get /v1/tax_rates', :list_tax_rates
      end

      def update_tax_rate(route, method_url, params, headers)
        route =~ method_url
        rate = assert_existence :tax_rate, $1, tax_rates[$1]
        rate.merge!(params)
        rate
      end

      def new_tax_rate(route, method_url, params, headers)
        params[:id] ||= new_id('txr')
        tax_rates[ params[:id] ] = Data.mock_tax_rate(params)
        tax_rates[ params[:id] ]
      end

      def list_tax_rates(route, method_url, params, headers)
        Data.mock_list_object(tax_rates.values, params)
      end

      def get_tax_rate(route, method_url, params, headers)
        route =~ method_url
        tax_rate = assert_existence :tax_rate, $1, tax_rates[$1]
        tax_rate.clone
      end
    end
  end
end

