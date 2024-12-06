module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/instance_profile'

        # Retrieves information about an instance profile
        #
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/API_GetInstanceProfile.html
        # ==== Parameters
        # * instance_profile_name<~String> - Name of instance_profile to retrieve the information for
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'InstanceProfile'<~Hash>:
        #       * Arn<~String> -
        #       * CreateDate<~Date>
        #       * InstanceProfileId<~String> -
        #       * InstanceProfileName<~String> -
        #       * Path<~String> -
        #       * Roles<~Array> -
        #         role<~Hash>:
        #           * 'Arn'<~String> -
        #           * 'AssumeRolePolicyDocument'<~String<
        #           * 'Path'<~String> -
        #           * 'RoleId'<~String> -
        #           * 'RoleName'<~String> -
        #     * 'RequestId'<~String> - Id of the request
        def get_instance_profile(instance_profile_name)
          request({
            'Action'    => 'GetInstanceProfile',
            'InstanceProfileName'  => instance_profile_name,
            :parser     => Fog::Parsers::AWS::IAM::InstanceProfile.new
          })
        end
      end

      class Mock
        def get_instance_profile(instance_profile_name)
          response = Excon::Response.new

          instance_profile = self.data[:instance_profiles][instance_profile_name]
          unless instance_profile
            raise Fog::AWS::IAM::NotFound.new("Instance Profile #{instance_profile_name} cannot be found.")
          end

          instance_profile = instance_profile.dup
          instance_profile["Roles"].map! { |r| self.data[:roles][r] }

          response.body = {"InstanceProfile" => instance_profile, "RequestId" => Fog::AWS::Mock.request_id}
          response
        end
      end
    end
  end
end
