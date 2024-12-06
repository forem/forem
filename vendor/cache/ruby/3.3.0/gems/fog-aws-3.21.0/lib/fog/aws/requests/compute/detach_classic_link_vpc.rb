module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/basic'
        # Links an EC2-Classic instance to a ClassicLink-enabled VPC through one or more of the VPC's security groups
        #
        # ==== Parameters
        # * vpc_id<~String>    - The ID of the vpc to which the instance is linkced.
        # * instance_id<~String> - The ID of an EC2-Classic instance to unlink from the vpc.
        # * security_group_ids<~String> - The ID of one or more of the VPC's security groups. You cannot specify security groups from a different VPC.
        # * dry_run<~Boolean> - defaults to false
        #
        # === Returns
        # * response<~Excon::Response>:
        # * body<~Hash>:
        # * 'requestId'<~String>           - Id of request
        # * 'return'<~Boolean>             - Whether the request succeeded
        #
        # (Amazon API Reference)[http://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DetachClassicLinkVpc.html]
        def detach_classic_link_vpc(instance_id, vpc_id, dry_run=false)
          request(
            'Action'    => 'DetachClassicLinkVpc',
            'VpcId'     => vpc_id,
            'InstanceId'=> instance_id,
            'DryRun'    => dry_run,
            :parser     => Fog::Parsers::AWS::Compute::Basic.new
          )
        end
      end


      class Mock
        def detach_classic_link_vpc(instance_id, vpc_id, dry_run=false)
          response = Excon::Response.new
          vpc = self.data[:vpcs].find{ |v| v['vpcId'] == vpc_id }
          instance = self.data[:instances][instance_id]
          if vpc && instance
            response.status = 200
            response.body = {
              'requestId' => Fog::AWS::Mock.request_id,
              'return'    => true
            }
            unless dry_run
              instance['classicLinkSecurityGroups'] = nil
              instance['classicLinkVpcId'] = nil
            end
            response
          elsif !instance
            raise Fog::AWS::Compute::NotFound.new("The instance ID '#{instance_id}' does not exist.")
          elsif !vpc
            raise Fog::AWS::Compute::NotFound.new("The VPC '#{vpc_id}' does not exist.")
          end
        end
      end
    end
  end
end
