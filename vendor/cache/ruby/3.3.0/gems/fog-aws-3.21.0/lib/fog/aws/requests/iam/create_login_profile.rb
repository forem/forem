module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/login_profile'

        # Creates a login profile for a user
        #
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/API_CreateLoginProfile.html
        # ==== Parameters
        # * user_name<~String> - Name of user to create a login profile for
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
        def create_login_profile(user_name, password)
          request({
            'Action'    => 'CreateLoginProfile',
            'UserName'  => user_name,
            'Password'  => password,
            :parser     => Fog::Parsers::AWS::IAM::LoginProfile.new
          })
        end
      end

      class Mock
        def create_login_profile(user_name, password)
          unless self.data[:users].key?(user_name)
            raise Fog::AWS::IAM::NotFound.new("The user with name #{user_name} cannot be found.")
          end

          user = self.data[:users][user_name]

          if user[:login_profile]
            raise Fog::AWS::IAM::EntityAlreadyExists, "Login Profile for user #{user_name} already exists."
          end

          created_at = Time.now

          user[:login_profile] = {
            :created_at => created_at,
            :password   => password,
          }

          response = Excon::Response.new
          response.status = 200

          response.body = {
            "LoginProfile" => {
              "UserName"   => user_name,
              "CreateDate" => created_at
            },
            "RequestId" => Fog::AWS::Mock.request_id
          }

          response
        end
      end
    end
  end
end
