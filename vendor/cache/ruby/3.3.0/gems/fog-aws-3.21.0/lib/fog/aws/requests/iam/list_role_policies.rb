module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/list_policies'

        # Lists the names of policies associated with a role
        #
        # ==== Parameters
        # * role_name<~String>: the role to list policies for
        # * options<~Hash>:
        #   * 'Marker'<~String>: used to paginate subsequent requests
        #   * 'MaxItems'<~Integer>: limit results to this number per page
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'PolicyNames'<~Array>:
        #       * policy_name <~String>
        #     * 'IsTruncated<~Boolean> - Whether or not results were truncated
        #     * 'Marker'<~String> - appears when IsTruncated is true as the next marker to use
        #     * 'RequestId'<~String> - Id of the request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/API_ListRoleProfiles.html
        #
        def list_role_policies(role_name,options={})
          request({
            'Action'    => 'ListRolePolicies',
            'RoleName'  => role_name,
            :parser     => Fog::Parsers::AWS::IAM::ListPolicies.new
          }.merge!(options))
        end
      end
    end
  end
end
