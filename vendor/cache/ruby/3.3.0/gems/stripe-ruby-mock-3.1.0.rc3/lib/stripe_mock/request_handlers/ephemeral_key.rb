module StripeMock
  module RequestHandlers
    module EphemeralKey
      def self.included(klass)
        klass.add_handler 'post /v1/ephemeral_keys', :create_ephemeral_key
      end

      def create_ephemeral_key(route, method_url, params, headers)
        Data.mock_ephemeral_key(**params)
      end
    end
  end
end
