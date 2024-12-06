module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/create_security_group'

        # Create a new security group
        #
        # ==== Parameters
        # * group_name<~String> - Name of the security group.
        # * group_description<~String> - Description of group.
        # * vpc_id<~String> - ID of the VPC
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - Id of request
        #     * 'return'<~Boolean> - success?
        #     * 'groupId'<~String> - Id of created group
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateSecurityGroup.html]
        def create_security_group(name, description, vpc_id=nil)
          request(
            'Action'            => 'CreateSecurityGroup',
            'GroupName'         => name,
            'GroupDescription'  => description,
            'VpcId'             => vpc_id,
            :parser             => Fog::Parsers::AWS::Compute::CreateSecurityGroup.new
          )
        end
      end

      class Mock
        def create_security_group(name, description, vpc_id=nil)
          response = Excon::Response.new

          vpc_id ||= Fog::AWS::Mock.default_vpc_for(region)
          group_id = Fog::AWS::Mock.security_group_id

          if self.data[:security_groups].find { |_,v| v['groupName'] == name }
            raise Fog::AWS::Compute::Error,
              "InvalidGroup.Duplicate => The security group '#{name}' already exists"
          end

          self.data[:security_groups][group_id] = {
            'groupDescription'    => description,
            'groupName'           => name,
            'groupId'             => group_id,
            'ipPermissionsEgress' => [],
            'ipPermissions'       => [],
            'ownerId'             => self.data[:owner_id],
            'vpcId'               => vpc_id
          }

          response.body = {
            'requestId' => Fog::AWS::Mock.request_id,
            'groupId'   => group_id,
            'return'    => true
          }
          response
        end
      end
    end
  end
end
