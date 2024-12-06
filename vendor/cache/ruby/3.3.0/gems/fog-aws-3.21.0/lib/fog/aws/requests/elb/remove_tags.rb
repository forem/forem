module Fog
  module AWS
    class ELB
      class Real

        # removes tags from an elastic load balancer instance
        # http://docs.aws.amazon.com/ElasticLoadBalancing/latest/APIReference/API_RemoveTags.html
        # ==== Parameters
        # * elb_id <~String> - name of the ELB instance whose tags are to be retrieved
        # * keys <~Array> A list of String keys for the tags to remove
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def remove_tags(elb_id, keys)
          request(
            { 'Action'                      => 'RemoveTags',
              # Note: there is a discrepancy in the API docs in the ID parameter name between the write-up and the example.
              # Who knows which way the fix will go, if any is ever made? In any case, this works.
              'LoadBalancerNames.member.1'  => elb_id,
              :parser => Fog::Parsers::AWS::ELB::Empty.new,
            }.merge(Fog::AWS.indexed_param('Tags.member.%d.Key', keys))
          )
        end

      end

      class Mock

        def remove_tags(elb_id, keys)
          response = Excon::Response.new
          if server = self.data[:load_balancers][elb_id]
            keys.each {|key| self.data[:tags][elb_id].delete key}
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
