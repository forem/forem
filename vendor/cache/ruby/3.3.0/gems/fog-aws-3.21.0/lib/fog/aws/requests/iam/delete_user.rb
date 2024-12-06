module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/basic'

        # Delete a user
        #
        # ==== Parameters
        # * user_name<~String>: name of the user to delete
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'RequestId'<~String> - Id of the request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/API_DeleteUser.html
        #
        def delete_user(user_name)
          request(
            'Action'    => 'DeleteUser',
            'UserName'  => user_name,
            :parser     => Fog::Parsers::AWS::IAM::Basic.new
          )
        end
      end

      class Mock
        def delete_user(user_name)
          if data[:users].key? user_name
            data[:users].delete user_name
            Excon::Response.new.tap do |response|
              response.body = { 'RequestId' => Fog::AWS::Mock.request_id }
              response.status = 200
            end
          else
            raise Fog::AWS::IAM::NotFound.new("The user with name #{user_name} cannot be found.")
          end
        end
      end
    end
  end
end
