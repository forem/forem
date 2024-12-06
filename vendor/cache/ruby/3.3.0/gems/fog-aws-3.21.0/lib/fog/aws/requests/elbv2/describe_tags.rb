module Fog
  module AWS
    class ELBV2
      class Real
        require 'fog/aws/parsers/elbv2/describe_tags'

        # returns a Hash of tags for a load balancer
        # http://docs.aws.amazon.com/ElasticLoadBalancing/latest/APIReference/API_DescribeTags.html
        # ==== Parameters
        # * resource_arns <~Array> - ARN(s) of the ELB instance whose tags are to be retrieved
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def describe_tags(resource_arns)
          request({
              'Action' => 'DescribeTags',
              :parser  => Fog::Parsers::AWS::ELBV2::DescribeTags.new
            }.merge!(Fog::AWS.indexed_param('ResourceArns.member.%d', [*resource_arns]))
          )
        end
      end

      class Mock
        def describe_tags(resource_arns)
          response = Excon::Response.new
          resource_arns = [*resource_arns]

          tag_describtions = resource_arns.map do |resource_arn|
            if self.data[:load_balancers_v2][resource_arn]
              {
                "Tags"=>self.data[:tags][resource_arn],
                "ResourceArn"=>resource_arn
              }
            else
              raise Fog::AWS::ELBV2::NotFound.new("Elastic load balancer #{resource_arns} not found")
            end
          end

          response.status = 200
          response.body = {
            "ResponseMetadata"=>{"RequestId"=> Fog::AWS::Mock.request_id },
            "DescribeTagsResult"=>{"TagDescriptions"=> tag_describtions}
          }

          response
        end
      end
    end
  end
end
