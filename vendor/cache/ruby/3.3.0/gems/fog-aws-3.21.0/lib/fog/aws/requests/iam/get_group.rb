module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/get_group'

        # Get Group
        #
        # ==== Parameters
        # * 'GroupName'<~String>: Name of the Group
        # * options<~Hash>:
        #   * 'Marker'<~String>: Use this only when paginating results, and only in a subsequent request after you've received a response where the results are truncated. Set it to the value of the Marker element in the response you just received.
        #   * 'MaxItems'<~String>: Use this only when paginating results to indicate the maximum number of User names you want in the response. If there are additional User names beyond the maximum you specify, the IsTruncated response element is true.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'Group'<~Hash> - Group
        #       * 'Path'<~String>
        #       * 'GroupName'<~String>
        #       * 'Arn'<~String>
        #     * 'Users'<~Hash>? - List of users belonging to the group.
        #       * 'User'<~Hash> - User
        #         * Arn<~String> -
        #         * UserId<~String> -
        #         * UserName<~String> -
        #         * Path<~String> -
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/index.html?API_GetGroup.html
        #
        def get_group(group_name, options = {})
          request({
            'Action'    => 'GetGroup',
            'GroupName' => group_name,
            :parser     => Fog::Parsers::AWS::IAM::GetGroup.new
          }.merge!(options))
        end
      end
      class Mock
        def get_group(group_name, options = {})
          raise Fog::AWS::IAM::NotFound.new(
            "The user with name #{group_name} cannot be found."
          ) unless self.data[:groups].key?(group_name)
          Excon::Response.new.tap do |response|
            response.body = { 'Group' =>  {
                                             'GroupId'   => data[:groups][group_name][:group_id],
                                             'Path'      => data[:groups][group_name][:path],
                                             'GroupName' => group_name,
                                             'Arn'       => (data[:groups][group_name][:arn]).strip
                                          },
                              'Users' => data[:groups][group_name][:members].map { |user| get_user(user).body['User'] },
                              'RequestId'   => Fog::AWS::Mock.request_id }
            response.status = 200
          end
        end
      end
    end
  end
end
