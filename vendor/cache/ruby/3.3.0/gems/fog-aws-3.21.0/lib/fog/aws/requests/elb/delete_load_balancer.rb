module Fog
  module AWS
    class ELB
      class Real
        require 'fog/aws/parsers/elb/delete_load_balancer'

        # Delete an existing Elastic Load Balancer
        #
        # Note that this API call, as defined by Amazon, is idempotent.
        # That is, it will not return an error if you try to delete an
        # ELB that does not exist.
        #
        # ==== Parameters
        # * lb_name<~String> - Name of the ELB to be deleted
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'DeleteLoadBalancerResponse'<~nil>
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        def delete_load_balancer(lb_name)
          request({
            'Action'           => 'DeleteLoadBalancer',
            'LoadBalancerName' => lb_name,
            :parser            => Fog::Parsers::AWS::ELB::DeleteLoadBalancer.new
          })
        end
      end

      class Mock
        def delete_load_balancer(lb_name)
          response = Excon::Response.new
          response.status = 200

          self.data[:load_balancers].delete(lb_name)

          response.body = {
            'ResponseMetadata' => {
              'RequestId' => Fog::AWS::Mock.request_id
            },
            'DeleteLoadBalancerResult' => nil
          }

          response
        end
      end
    end
  end
end
