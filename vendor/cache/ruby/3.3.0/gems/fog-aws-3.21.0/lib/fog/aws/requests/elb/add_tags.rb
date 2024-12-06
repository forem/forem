module Fog
  module AWS
    class ELB
      class Real

        # adds tags to a load balancer instance
        # http://docs.aws.amazon.com/ElasticLoadBalancing/latest/APIReference/API_AddTags.html
        # ==== Parameters
        # * elb_id <~String> - name of the ELB instance to be tagged
        # * tags <~Hash> A Hash of (String) key-value pairs
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def add_tags(elb_id, tags)
          keys    = tags.keys.sort
          values  = keys.map {|key| tags[key]}
          request({
              'Action'                     => 'AddTags',
              'LoadBalancerNames.member.1' => elb_id,
              :parser                      => Fog::Parsers::AWS::ELB::Empty.new,
            }.merge(Fog::AWS.indexed_param('Tags.member.%d.Key', keys)).
              merge(Fog::AWS.indexed_param('Tags.member.%d.Value', values)))
        end

      end

      class Mock

        def add_tags(elb_id, tags)
          response = Excon::Response.new
          if server = self.data[:load_balancers][elb_id]
            self.data[:tags][elb_id].merge! tags
            response.status = 200
            response.body = {
              "ResponseMetadata"=>{ "RequestId"=> Fog::AWS::Mock.request_id }
            }
            response
          else
            raise Fog::AWS::ELB::NotFound.new("Elastic load balancer #{elb_id} not found")
          end
        end

      end
    end
  end
end
