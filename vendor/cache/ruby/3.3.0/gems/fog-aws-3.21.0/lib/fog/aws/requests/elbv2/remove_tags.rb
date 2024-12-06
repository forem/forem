module Fog
  module AWS
    class ELBV2
      class Real
        require 'fog/aws/parsers/elbv2/empty'

        # removes tags from an elastic load balancer instance
        # http://docs.aws.amazon.com/ElasticLoadBalancing/latest/APIReference/API_RemoveTags.html
        # ==== Parameters
        # * resource_arn <~String> - ARN of the ELB instance whose tags are to be retrieved
        # * keys <~Array> A list of String keys for the tags to remove
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def remove_tags(resource_arn, keys)
          request(
            { 'Action'                      => 'RemoveTags',
              'ResourceArns.member.1'  => resource_arn,
              :parser => Fog::Parsers::AWS::ELBV2::Empty.new,
            }.merge(Fog::AWS.indexed_param('TagKeys.member.%d', keys))
          )
        end

      end

      class Mock

        def remove_tags(resource_arn, keys)
          response = Excon::Response.new
          if self.data[:load_balancers_v2][resource_arn]
            keys.each {|key| self.data[:tags][resource_arn].delete key}
            response.status = 200
            response.body = {
              "ResponseMetadata"=>{ "RequestId"=> Fog::AWS::Mock.request_id }
            }
            response
          else
            raise Fog::AWS::ELBV2::NotFound.new("Elastic load balancer #{resource_arn} not found")
          end
        end

      end
    end
  end
end
