module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/basic'

        # removes a role from an instance profile
        #
        # Make sure you do not have any Amazon EC2 instances running with the role you are about to remove from the instance profile.
        # ==== Parameters
        # * instance_profile_name<~String>: Name of the instance profile to update.
        # * role_name<~String>:Name of the role to remove.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'RequestId'<~String> - Id of the request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/API_RemoveRoleFromInstanceProfile.html
        #
        def remove_role_from_instance_profile(role_name, instance_profile_name)
          request(
            'Action'    => 'RemoveRoleFromInstanceProfile',
            'InstanceProfileName' => instance_profile_name,
            'RoleName'  => role_name,
            :parser     => Fog::Parsers::AWS::IAM::Basic.new
          )
        end
      end

      class Mock
        def remove_role_from_instance_profile(role_name, instance_profile_name)
          response = Excon::Response.new

          unless profile = self.data[:instance_profiles][instance_profile_name]
            raise Fog::AWS::IAM::NotFound.new("Instance Profile #{instance_profile_name} cannot be found.")
          end

          unless role = self.data[:roles][role_name]
            raise Fog::AWS::IAM::NotFound.new("Role #{role_name} cannot be found.")
          end

          profile["Roles"].delete(role_name)

          response.body = {"RequestId" => Fog::AWS::Mock.request_id}
          response
        end
      end
    end
  end
end
