module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/list_groups_for_user'

        # List groups_for_user
        #
        # ==== Parameters
        # * user_name<~String> - the username you want to look up group membership for
        # * options<~Hash>:
        #   * 'Marker'<~String> - used to paginate subsequent requests
        #   * 'MaxItems'<~Integer> - limit results to this number per page
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'GroupsForUser'<~Array> - Groups for a user
        #       * group_for_user<~Hash>:
        #         * 'Arn' -
        #         * 'GroupId' -
        #         * 'GroupName' -
        #         * 'Path' -
        #     * 'IsTruncated'<~Boolean> - Whether or not results were truncated
        #     * 'Marker'<~String> - appears when IsTruncated is true as the next marker to use
        #     * 'RequestId'<~String> - Id of the request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/API_ListGroupsForUser.html
        #
        def list_groups_for_user(user_name, options = {})
          request({
            'Action'    => 'ListGroupsForUser',
            'UserName'  => user_name,
            :parser     => Fog::Parsers::AWS::IAM::ListGroupsForUser.new
          }.merge!(options))
        end
      end

      class Mock
        def list_groups_for_user(user_name, options = {})
          #FIXME: Does not consider options
          if data[:users].key? user_name
            Excon::Response.new.tap do |response|
              response.status = 200
              response.body = { 'GroupsForUser' => data[:groups].select do |name, group|
                                                     group[:members].include? user_name
                                                   end.map do |name, group|
                                                     { 'GroupId'   => group[:group_id],
                                                       'GroupName' => name,
                                                       'Path'      => group[:path],
                                                       'Arn'       => (group[:arn]).strip }
                                                   end,
                                'IsTruncated' => false,
                                'RequestId' => Fog::AWS::Mock.request_id
                              }
            end
          else
            raise Fog::AWS::IAM::NotFound.new("The user with name #{user_name} cannot be found.")
          end
        end
      end
    end
  end
end
