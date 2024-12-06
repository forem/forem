module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/basic'

        # Updates a login profile for a user
        #
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/API_UpdateLoginProfile.html
        # ==== Parameters
        # * user_name<~String> - Name of user to change the login profile for
        # * password<~String> - The new password for this user
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'RequestId'<~String> - Id of the request
        #
        #
        def update_login_profile(user_name, password)
          request({
            'Action'    => 'UpdateLoginProfile',
            'UserName'  => user_name,
            'Password'  => password,
            :parser     => Fog::Parsers::AWS::IAM::Basic.new
          })
        end
      end

      class Mock
        def update_login_profile(user_name, password)
          unless self.data[:users].key?(user_name)
            raise Fog::AWS::IAM::NotFound.new("The user with name #{user_name} cannot be found.")
          end

          user = self.data[:users][user_name]

          unless user[:login_profile]
            raise Fog::AWS::IAM::NotFound, "Cannot find Login Profile for User #{user_name}"
          end

          user[:login_profile][:password] = password

          response = Excon::Response.new
          response.status = 200

          response.body = {
            "RequestId" => Fog::AWS::Mock.request_id
          }

          response
        end
      end
    end
  end
end
