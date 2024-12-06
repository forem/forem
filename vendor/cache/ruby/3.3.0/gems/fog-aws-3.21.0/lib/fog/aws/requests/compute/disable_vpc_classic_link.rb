module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/basic'
        # disavbles classic link for a vpc
        #
        # ==== Parameters
        # * vpc_id<~String>    - The ID of the VPC you want to describe an attribute of
        # * dry_run<~Boolean> - defaults to false
        #
        # === Returns
        # * response<~Excon::Response>:
        # * body<~Hash>:
        # * 'requestId'<~String>           - Id of request
        # * 'return'<~Boolean>             - Whether the request succeeded
        #
        # (Amazon API Reference)[http://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DisableVpcClassicLink.html]
        def disable_vpc_classic_link(vpc_id, dry_run=false)
          request(
            'Action'    => 'DisableVpcClassicLink',
            'VpcId'     => vpc_id,
            'DryRun'    => dry_run,
            :parser     => Fog::Parsers::AWS::Compute::Basic.new
          )
        end
      end

      class Mock
        def disable_vpc_classic_link(vpc_id, dry_run=false)
          response = Excon::Response.new
          if vpc = self.data[:vpcs].find{ |v| v['vpcId'] == vpc_id }
            response.status = 200
            response.body = {
              'requestId' => Fog::AWS::Mock.request_id,
              'return'    => true
            }
            vpc['classicLinkEnabled'] = false unless dry_run
            response
          else
            raise Fog::AWS::Compute::NotFound.new("The VPC '#{vpc_id}' does not exist")
          end
        end
      end
    end
  end
end
