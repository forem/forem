module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/login_profile'

        # Retrieves the login profile for a user
        #
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/API_CreateLoginProfile.html
        # ==== Parameters
        # * user_name<~String> - Name of user to retrieve the login profile for
        # * password<~String> - The new password for this user
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'LoginProfile'<~Hash>
        #        * UserName<~String>
        #        * CreateDate
        #     * 'RequestId'<~String> - Id of the request
        #
        #
        def get_login_profile(user_name)
          request({
            'Action'    => 'GetLoginProfile',
            'UserName'  => user_name,
            :parser     => Fog::Parsers::AWS::IAM::LoginProfile.new
          })
        end
      end

      class Mock
        def get_login_profile(user_name)
          unless self.data[:users].key?(user_name)
            raise Fog::AWS::IAM::NotFound.new("The user with name #{user_name} cannot be found.")
          end

          profile = self.data[:users][user_name][:login_profile]

          unless profile
            raise Fog::AWS::IAM::NotFound, "Cannot find Login Profile for User #{user_name}"
          end

          response = Excon::Response.new
          response.status = 200

          response.body = {
            "LoginProfile" => {
              "UserName"   => user_name,
              "CreateDate" => profile[:created_at]
            },
            "RequestId" => Fog::AWS::Mock.request_id
          }

          response
        end
      end
    end
  end
end
