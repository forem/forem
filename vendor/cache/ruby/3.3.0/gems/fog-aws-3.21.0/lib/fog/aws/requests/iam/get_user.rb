module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/get_user'

        # Get User
        #
        # ==== Parameters
        # * username<String>
        # * options<~Hash>:
        #   * 'UserName'<~String>: Name of the User. Defaults to current user
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'User'<~Hash> - User
        #       * Arn<~String> -
        #       * UserId<~String> -
        #       * UserName<~String> -
        #       * Path<~String> -
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/API_Getuser.html
        #
        def get_user(username = nil, options = {})
          params = {
            'Action' => 'GetUser',
            :parser  => Fog::Parsers::AWS::IAM::GetUser.new
          }

          if username
            params.merge!('UserName' => username)
          end

          request(params.merge(options))
        end
      end

      class Mock
        def get_user(username = nil, options = {})
          response  = Excon::Response.new
          user_body = nil

          if username.nil? # show current user
            user = self.current_user

            user_body = {
              'UserId'     => user[:user_id],
              'Arn'        => user[:arn].strip,
              'CreateDate' => user[:created_at]
            }

            unless @current_user_name == "root"
              user_body.merge!(
                'Path'     => user[:path],
                'UserName' => @current_user_name
              )
            end

          elsif !self.data[:users].key?(username)
            raise Fog::AWS::IAM::NotFound.new("The user with name #{username} cannot be found.")
          else
            user = self.data[:users][username]

            user_body = {
              'UserId'     => user[:user_id],
              'Path'       => user[:path],
              'UserName'   => username,
              'Arn'        => user[:arn].strip,
              'CreateDate' => user[:created_at]
            }
          end

          response.status = 200
          response.body = {
            'User'      => user_body,
            'RequestId' => Fog::AWS::Mock.request_id
          }

          response
        end
      end
    end
  end
end
