module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/basic'

        # Delete a role
        #
        # ==== Parameters
        # * role_name<~String>: name of the role to delete
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'RequestId'<~String> - Id of the request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/API_DeleteRole.html
        #
        def delete_role(role_name)
          request(
            'Action'    => 'DeleteRole',
            'RoleName'  => role_name,
            :parser     => Fog::Parsers::AWS::IAM::Basic.new
          )
        end
      end

      class Mock
        def delete_role(role_name)
          role = data[:roles][role_name]

          if role
            data[:roles].delete(role_name)
            Excon::Response.new.tap do |response|
              response.status = 200
              response.body   = { 'RequestId' => Fog::AWS::Mock.request_id }
            end
          else
            raise Fog::AWS::IAM::NotFound.new("The role with name #{role_name} cannot be found.")
          end
        end
      end
    end
  end
end
