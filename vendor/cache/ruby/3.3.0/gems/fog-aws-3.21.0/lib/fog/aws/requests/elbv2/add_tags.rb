module Fog
  module AWS
    class ELBV2
      class Real
        require 'fog/aws/parsers/elbv2/empty'

        # adds tags to a load balancer instance
        # http://docs.aws.amazon.com/ElasticLoadBalancing/latest/APIReference/API_AddTags.html
        # ==== Parameters
        # * resource_arn <~String> - The Amazon Resource Name (ARN) of the resource
        # * tags <~Hash> A Hash of (String) key-value pairs
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def add_tags(resource_arn, tags)
          keys    = tags.keys.sort
          values  = keys.map {|key| tags[key]}
          request({
              'Action'                     => 'AddTags',
              'ResourceArns.member.1'      => resource_arn,
              :parser                      => Fog::Parsers::AWS::ELBV2::Empty.new,
            }.merge(Fog::AWS.indexed_param('Tags.member.%d.Key', keys))
             .merge(Fog::AWS.indexed_param('Tags.member.%d.Value', values)))
        end

      end

      class Mock
        def add_tags(resource_arn, tags)
          response = Excon::Response.new
          if self.data[:load_balancers_v2][resource_arn]
            self.data[:tags][resource_arn].merge! tags
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
