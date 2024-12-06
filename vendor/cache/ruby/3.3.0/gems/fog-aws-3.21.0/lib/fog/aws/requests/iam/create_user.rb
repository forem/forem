module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/create_user'

        # Create a new user
        #
        # ==== Parameters
        # * user_name<~String>: name of the user to create (do not include path)
        # * path<~String>: optional path to group, defaults to '/'
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'User'<~Hash>:
        #       * 'Arn'<~String> -
        #       * 'Path'<~String> -
        #       * 'UserId'<~String> -
        #       * 'UserName'<~String> -
        #     * 'RequestId'<~String> - Id of the request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/API_CreateUser.html
        #
        def create_user(user_name, path = '/')
          request(
            'Action'    => 'CreateUser',
            'UserName'  => user_name,
            'Path'      => path,
            :parser     => Fog::Parsers::AWS::IAM::CreateUser.new
          )
        end
      end

      class Mock
        def create_user(user_name, path='/')
          if data[:users].key?(user_name)
            raise Fog::AWS::IAM::EntityAlreadyExists.new "User with name #{user_name} already exists."
          end

          data[:users][user_name][:path] = path

          Excon::Response.new.tap do |response|
            response.status = 200
            response.body = { 'User' => {
              "UserId"     => data[:users][user_name][:user_id],
              "Path"       => path,
              "UserName"   => user_name,
              "Arn"        => (data[:users][user_name][:arn]).strip,
            },
            'RequestId' => Fog::AWS::Mock.request_id
            }
          end
        end
      end
    end
  end
end
