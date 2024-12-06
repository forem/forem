module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/basic'
        # Links an EC2-Classic instance to a ClassicLink-enabled VPC through one or more of the VPC's security groups
        #
        # ==== Parameters
        # * vpc_id<~String>    - The ID of a ClassicLink-enabled VPC.
        # * instance_id<~String> - The ID of an EC2-Classic instance to link to the ClassicLink-enabled VPC.
        # * security_group_ids<~String> - The ID of one or more of the VPC's security groups. You cannot specify security groups from a different VPC.
        # * dry_run<~Boolean> - defaults to false
        #
        # === Returns
        # * response<~Excon::Response>:
        # * body<~Hash>:
        # * 'requestId'<~String>           - Id of request
        # * 'return'<~Boolean>             - Whether the request succeeded
        #
        # (Amazon API Reference)[http://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_AttachClassicLinkVpc.html]
        def attach_classic_link_vpc(instance_id, vpc_id, security_group_ids, dry_run=false)
          request({
            'Action'    => 'AttachClassicLinkVpc',
            'VpcId'     => vpc_id,
            'InstanceId'=> instance_id,
            'DryRun'    => dry_run,
            :parser     => Fog::Parsers::AWS::Compute::Basic.new
          }.merge(Fog::AWS.indexed_param('SecurityGroupId', security_group_ids)))

        end
      end


      class Mock
        def attach_classic_link_vpc(instance_id, vpc_id, security_group_ids, dry_run=false)
          response = Excon::Response.new
          vpc = self.data[:vpcs].find{ |v| v['vpcId'] == vpc_id }
          instance = self.data[:instances][instance_id]
          if vpc && instance
            if instance['instanceState']['name'] != 'running' || instance['vpcId']
              raise Fog::AWS::Compute::Error.new("Client.InvalidInstanceID.NotLinkable => Instance #{instance_id} is unlinkable")
            end
            if instance['classicLinkVpcId']
              raise Fog::AWS::Compute::Error.new("Client.InvalidInstanceID.InstanceAlreadyLinked => Instance #{instance_id} is already linked")
            end

            response.status = 200
            response.body = {
              'requestId' => Fog::AWS::Mock.request_id,
              'return'    => true
            }
            unless dry_run
              instance['classicLinkSecurityGroups'] = security_group_ids
              instance['classicLinkVpcId'] = vpc_id
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
