module Fog
  module AWS
    class ELB
      class Real

        require 'fog/aws/parsers/elb/tag_list_parser'

        # returns a Hash of tags for a load balancer
        # http://docs.aws.amazon.com/ElasticLoadBalancing/latest/APIReference/API_DescribeTags.html
        # ==== Parameters
        # * elb_id <~String> - name(s) of the ELB instance whose tags are to be retrieved (allows 1-20 of them)
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def describe_tags(elb_ids)
          request({
              'Action' => 'DescribeTags',
              :parser  => Fog::Parsers::AWS::ELB::TagListParser.new
            }.merge(Fog::AWS.indexed_param('LoadBalancerNames.member.%d', elb_ids))
          )
        end
        # def describe_tags(filters = {})
        #   params = Fog::AWS.indexed_filters(filters)
        #   request({
        #     'Action'    => 'DescribeTags',
        #     :idempotent => true,
        #     :parser     => Fog::Parsers::AWS::Compute::DescribeTags.new
        #   }.merge!(params))
        # end

      end

      class Mock

        def describe_tags(elb_id)
          response = Excon::Response.new

          if server = self.data[:load_balancers][elb_id]
            response.status = 200
            ##{"DescribeTagsResult"=>{"LoadBalancers"=>[{"Tags"=>{"Name"=>"2esakowski-test-opsworks-elb"}, "LoadBalancerName"=>"esakowski-test-opsworks"}]}}
            response.body = {"DescribeTagsResult"=>{"LoadBalancers"=>[{"Tags"=>self.data[:tags][elb_id], "LoadBalancerName"=>elb_id}]}}

#            response.body = {
#              "DescribeTagsResult" =>
#               {"TagDescriptions" => self.data[:tags][elb_id]}
#            }
            response
          else
            raise Fog::AWS::ELB::NotFound.new("Elastic load balancer #{elb_id} not found")
          end
        end

      end
    end
  end
end
