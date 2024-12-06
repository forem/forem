module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/list_users'

        # List users
        #
        # ==== Parameters
        # * options<~Hash>:
        #   * 'Marker'<~String>: used to paginate subsequent requests
        #   * 'MaxItems'<~Integer>: limit results to this number per page
        #   * 'PathPrefix'<~String>: prefix for filtering results
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'Users'<~Array> - Matching groups
        #       * user<~Hash>:
        #         * Arn<~String> -
        #         * Path<~String> -
        #         * UserId<~String> -
        #         * UserName<~String> -
        #     * 'IsTruncated<~Boolean> - Whether or not results were truncated
        #     * 'Marker'<~String> - appears when IsTruncated is true as the next marker to use
        #     * 'RequestId'<~String> - Id of the request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/API_ListUsers.html
        #
        def list_users(options = {})
          request({
            'Action'  => 'ListUsers',
            :parser   => Fog::Parsers::AWS::IAM::ListUsers.new
          }.merge!(options))
        end
      end

      class Mock
        def list_users(options = {})
          #FIXME: none of the options are currently supported
          Excon::Response.new.tap do |response|
            response.body = {'Users' => data[:users].map do |user, data|
                                          { 'UserId'     => data[:user_id],
                                            'Path'       => data[:path],
                                            'UserName'   => user,
                                            'Arn'        => (data[:arn]).strip,
                                            'CreateDate' => data[:created_at]}
                                        end,
                             'IsTruncated' => false,
                             'RequestId'   => Fog::AWS::Mock.request_id }
            response.status = 200
          end
        end
      end
    end
  end
end
