module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/list_instance_profiles'

        # Lists the instance profiles that have the specified associated role
        #
        # ==== Parameters
        # * options<~Hash>:
        #   * 'Marker'<~String>: used to paginate subsequent requests
        #   * 'MaxItems'<~Integer>: limit results to this number per page
        # * 'RoleName'<~String>: The name of the role to list instance profiles for.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'InstanceProfiles'<~Array>:
        #       * instance_profile <~Hash>:
        #         * Arn<~String> -
        #         * CreateDate<~Date>
        #         * InstanceProfileId<~String> -
        #         * InstanceProfileName<~String> -
        #         * Path<~String> -
        #         * Roles<~Array> -
        #           role<~Hash>:
        #             * 'Arn'<~String> -
        #             * 'AssumeRolePolicyDocument'<~String<
        #             * 'Path'<~String> -
        #             *  'RoleId'<~String> -
        #             * 'RoleName'<~String> -
        #     * 'IsTruncated<~Boolean> - Whether or not results were truncated
        #     * 'Marker'<~String> - appears when IsTruncated is true as the next marker to use
        #     * 'RequestId'<~String> - Id of the request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/API_ListInstanceProfilesForRole.html
        #
        def list_instance_profiles_for_role(role_name,options={})
          request({
            'Action'    => 'ListInstanceProfilesForRole',
            'RoleName'  => role_name,
            :parser     => Fog::Parsers::AWS::IAM::ListInstanceProfiles.new
          }.merge!(options))
        end
      end

      class Mock
        def list_instance_profiles_for_role(role_name, options={})
          response = Excon::Response.new

          profiles = self.data[:instance_profiles].values.select { |p| p["Roles"].include?(role_name) }
          response.body = { "InstanceProfiles" => profiles, "IsTruncated" => false, "RequestId" => Fog::AWS::Mock.request_id }
          response
        end
      end
    end
  end
end
