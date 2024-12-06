module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/describe_key_pairs'

        # Describe all or specified key pairs
        #
        # ==== Parameters
        # * filters<~Hash> - List of filters to limit results with
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - Id of request
        #     * 'keySet'<~Array>:
        #       * 'keyName'<~String> - Name of key
        #       * 'keyFingerprint'<~String> - Fingerprint of key
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeKeyPairs.html]
        def describe_key_pairs(filters = {})
          unless filters.is_a?(Hash)
            Fog::Logger.deprecation("describe_key_pairs with #{filters.class} param is deprecated, use describe_key_pairs('key-name' => []) instead [light_black](#{caller.first})[/]")
            filters = {'key-name' => [*filters]}
          end
          params = Fog::AWS.indexed_filters(filters)
          request({
            'Action'    => 'DescribeKeyPairs',
            :idempotent => true,
            :parser     => Fog::Parsers::AWS::Compute::DescribeKeyPairs.new
          }.merge!(params))
        end
      end

      class Mock
        def describe_key_pairs(filters = {})
          unless filters.is_a?(Hash)
            Fog::Logger.deprecation("describe_key_pairs with #{filters.class} param is deprecated, use describe_key_pairs('key-name' => []) instead [light_black](#{caller.first})[/]")
            filters = {'key-name' => [*filters]}
          end

          response = Excon::Response.new

          key_set = self.data[:key_pairs].values

          aliases = {'fingerprint' => 'keyFingerprint', 'key-name' => 'keyName'}
          for filter_key, filter_value in filters
            aliased_key = aliases[filter_key]
            key_set = key_set.reject{|key_pair| ![*filter_value].include?(key_pair[aliased_key])}
          end

          response.status = 200
          response.body = {
            'requestId' => Fog::AWS::Mock.request_id,
            'keySet'    => key_set.map do |key_pair|
              key_pair.reject {|key,value| !['keyFingerprint', 'keyName'].include?(key)}
            end
          }
          response
        end
      end
    end
  end
end
