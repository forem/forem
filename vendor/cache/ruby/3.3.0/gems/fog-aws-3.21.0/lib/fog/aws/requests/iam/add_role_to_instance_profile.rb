module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/basic'

        # Add a role to an instance profile
        #
        # ==== Parameters
        # * instance_profile_name<~String>: Name of the instance profile to update.
        # * role_name<~String>:Name of the role to add.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'RequestId'<~String> - Id of the request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/API_AddRoleToInstanceProfile.html
        #
        def add_role_to_instance_profile(role_name, instance_profile_name)
          request(
            'Action'    => 'AddRoleToInstanceProfile',
            'InstanceProfileName' => instance_profile_name,
            'RoleName'  => role_name,
            :parser     => Fog::Parsers::AWS::IAM::Basic.new
          )
        end
      end

      class Mock
        def add_role_to_instance_profile(role_name, instance_profile_name)
          response = Excon::Response.new

          unless profile = self.data[:instance_profiles][instance_profile_name]
            raise Fog::AWS::IAM::NotFound.new("Instance Profile #{instance_profile_name} cannot be found.")
          end

          unless role = self.data[:roles][role_name]
            raise Fog::AWS::IAM::NotFound.new("Role #{role_name} cannot be found.")
          end

          profile["Roles"] << role_name

          response.body = {"RequestId" => Fog::AWS::Mock.request_id}
          response
        end
      end
    end
  end
end
