module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/basic'

        # Deletes a user's login profile
        #
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/API_DeleteLoginProfile.html
        # ==== Parameters
        # * user_name<~String> - Name of user whose login profile you want to delete
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'RequestId'<~String> - Id of the request
        #
        #
        def delete_login_profile(user_name)
          request({
            'Action'    => 'DeleteLoginProfile',
            'UserName'  => user_name,
            :parser     => Fog::Parsers::AWS::IAM::Basic.new
          })
        end
      end

      class Mock
        def delete_login_profile(user_name)
          unless self.data[:users].key?(user_name)
            raise Fog::AWS::IAM::NotFound.new("The user with name #{user_name} cannot be found.")
          end

          user = self.data[:users][user_name]

          unless user[:login_profile]
            raise Fog::AWS::IAM::NotFound, "Cannot find Login Profile for User #{user_name}"
          end

          user.delete(:login_profile)

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
