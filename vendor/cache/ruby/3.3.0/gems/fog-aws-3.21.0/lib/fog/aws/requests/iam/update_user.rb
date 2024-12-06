module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/update_user'

        # Update a user
        #
        # ==== Parameters
        # * user_name<~String> - Required. Name of the User to update. If you're changing the name of the User, this is the original User name.
        # * options<~Hash>:
        #   * new_path<~String> - New path for the User. Include this parameter only if you're changing the User's path.
        #   * new_user_name<~String> - New name for the User. Include this parameter only if you're changing the User's name.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'RequestId'<~String> - Id of the request
        #     * 'User'<~Hash> - Changed user info
        #       * 'Arn'<~String> -
        #       * 'Path'<~String> -
        #       * 'UserId'<~String> -
        #       * 'UserName'<~String> -
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/index.html?API_UpdateUser.html
        #
        def update_user(user_name, options = {})
          request({
            'Action'      => 'UpdateUser',
            'UserName'    => user_name,
            :parser       => Fog::Parsers::AWS::IAM::UpdateUser.new
          }.merge!(options))
        end
      end
    end
  end
end
