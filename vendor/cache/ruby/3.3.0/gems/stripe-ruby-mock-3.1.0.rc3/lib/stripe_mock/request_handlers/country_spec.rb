module StripeMock
  module RequestHandlers
    module CountrySpec

      def CountrySpec.included(klass)
        klass.add_handler 'get /v1/country_specs/(.*)', :retrieve_country_spec
      end

      def retrieve_country_spec(route, method_url, params, headers)
        route =~ method_url

        unless ["AT", "AU", "BE", "CA", "DE", "DK", "ES", "FI", "FR", "GB", "IE", "IT", "JP", "LU", "NL", "NO", "SE", "SG", "US"].include?($1)
          raise Stripe::InvalidRequestError.new("#{$1} is not currently supported by Stripe.", $1.to_s)
        end

        country_spec[$1] ||= Data.mock_country_spec($1)

        assert_existence :country_spec, $1, country_spec[$1]
      end
    end
  end
end