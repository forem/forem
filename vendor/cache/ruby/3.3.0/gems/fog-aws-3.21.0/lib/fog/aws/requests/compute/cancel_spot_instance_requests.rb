module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/cancel_spot_instance_requests'

        # Terminate specified spot instance requests
        #
        # ==== Parameters
        # * spot_instance_request_id<~Array> - Ids of instances to terminates
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> id of request
        #     * 'spotInstanceRequestSet'<~Array>:
        #       * 'spotInstanceRequestId'<~String> - id of cancelled spot instance
        #       * 'state'<~String> - state of cancelled spot instance
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CancelSpotInstanceRequests.html]
        def cancel_spot_instance_requests(spot_instance_request_id)
          params = Fog::AWS.indexed_param('SpotInstanceRequestId', spot_instance_request_id)
          request({
            'Action'    => 'CancelSpotInstanceRequests',
            :idempotent => true,
            :parser     => Fog::Parsers::AWS::Compute::CancelSpotInstanceRequests.new
          }.merge!(params))
        end
      end

      class Mock
        def cancel_spot_instance_requests(spot_instance_request_id)
          response = Excon::Response.new
          spot_request = self.data[:spot_requests][spot_instance_request_id]

          unless spot_request
            raise Fog::AWS::Compute::NotFound.new("The spot instance request ID '#{spot_instance_request_id}' does not exist")
          end

          spot_request['fault']['code'] = 'request-cancelled'
          spot_request['state'] = 'cancelled'

          response.body = {'spotInstanceRequestSet' => [{'spotInstanceRequestId' => spot_instance_request_id, 'state' => 'cancelled'}], 'requestId' => Fog::AWS::Mock.request_id}
          response
        end
      end
    end
  end
end
