require 'fog/aws/models/elb/load_balancer'
module Fog
  module AWS
    class ELB
      class LoadBalancers < Fog::Collection
        model Fog::AWS::ELB::LoadBalancer

        # Creates a new load balancer
        def initialize(attributes = {})
          super
        end

        def all
          result = []
          marker = nil
          finished = false
          until finished
            data = service.describe_load_balancers('Marker' => marker).body
            result.concat(data['DescribeLoadBalancersResult']['LoadBalancerDescriptions'])
            marker = data['DescribeLoadBalancersResult']['NextMarker']
            finished = marker.nil?
          end
          load(result) # data is an array of attribute hashes
        end

        def get(identity)
          return unless identity
          data = service.describe_load_balancers('LoadBalancerNames' => identity).body['DescribeLoadBalancersResult']['LoadBalancerDescriptions'].first
          new(data)
        rescue Fog::AWS::ELB::NotFound
          nil
        end
      end
    end
  end
end
