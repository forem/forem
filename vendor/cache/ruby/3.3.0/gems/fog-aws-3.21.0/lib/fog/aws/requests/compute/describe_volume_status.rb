module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/describe_volume_status'

        # http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeVolumeStatus.html
        def describe_volume_status(filters = {})
          raise ArgumentError.new("Filters must be a hash, but is a #{filters.class}.") unless filters.is_a?(Hash)
          next_token = filters.delete('nextToken') || filters.delete('NextToken')
          max_results = filters.delete('maxResults') || filters.delete('MaxResults')

          params = Fog::AWS.indexed_request_param('VolumeId', filters.delete('VolumeId'))

          params.merge!(Fog::AWS.indexed_filters(filters))

          params['NextToken'] = next_token if next_token
          params['MaxResults'] = max_results if max_results

          request({
            'Action'    => 'DescribeVolumeStatus',
            :idempotent => true,
            :parser     => Fog::Parsers::AWS::Compute::DescribeVolumeStatus.new
          }.merge!(params))
        end
      end

      class Mock
        def describe_volume_status(filters = {})
          response = Excon::Response.new
          response.status = 200

          response.body = {
            'volumeStatusSet' => [],
            'requestId' => Fog::AWS::Mock.request_id
          }

          response
        end
      end
    end
  end
end
