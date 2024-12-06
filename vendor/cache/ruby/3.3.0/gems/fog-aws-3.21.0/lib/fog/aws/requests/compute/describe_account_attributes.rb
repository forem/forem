module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/describe_account_attributes'

        # Describe account attributes
        #
        # ==== Parameters
        # * filters<~Hash> - List of filters to limit results with
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> = Id of request
        #     * 'accountAttributeSet'<~Array>:
        #       * 'attributeName'<~String> - supported-platforms
        #       * 'attributeValueSet'<~Array>:
        #         * 'attributeValue'<~String> - Value of attribute
        #
        # {Amazon API Reference}[http://docs.aws.amazon.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeAccountAttributes.html]

        def describe_account_attributes(filters = {})
          params = Fog::AWS.indexed_filters(filters)
          request({
            'Action'    => 'DescribeAccountAttributes',
            :idempotent => true,
            :parser     => Fog::Parsers::AWS::Compute::DescribeAccountAttributes.new
          }.merge!(params))
        end
      end

      class Mock
        def describe_account_attributes(filters = {})
          account_attributes = self.data[:account_attributes]

          Excon::Response.new(
            :status => 200,
            :body => {
              'requestId'           => Fog::AWS::Mock.request_id,
              'accountAttributeSet' => account_attributes
            }
          )
        end
      end
    end
  end
end
