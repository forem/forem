module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/single_role'

        # Get the specified role
        #
        # ==== Parameters
        # role_name<~String>

        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * Role<~Hash>:
        #       * 'Arn'<~String> -
        #       * 'AssumeRolePolicyDocument'<~String<
        #       * 'Path'<~String> -
        #       * 'RoleId'<~String> -
        #       * 'RoleName'<~String> -
        #     * 'RequestId'<~String> - Id of the request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/API_GetRole.html
        #
        def get_role(role_name)
          request(
            'Action'    => 'GetRole',
            'RoleName'  => role_name,
            :parser     => Fog::Parsers::AWS::IAM::SingleRole.new
          )
        end
      end

      class Mock
        def get_role(role_name)

          unless self.data[:roles].key?(role_name)
            raise Fog::AWS::IAM::NotFound.new("The role with name #{role_name} cannot be found")
          end

          role = self.data[:roles][role_name]

          Excon::Response.new.tap do |response|
            response.body = {
              'Role' => {
                  'Arn'                      => role[:arn].strip,
                  'AssumeRolePolicyDocument' => Fog::JSON.encode(role[:assume_role_policy_document]),
                  'CreateDate'               => role[:create_date],
                  'Path'                     => role[:path],
                  'RoleId'                   => role[:role_id].strip,
                  'RoleName'                 => role_name,
              },
              'RequestId' => Fog::AWS::Mock.request_id
            }
            response.status = 200
          end
        end
      end
    end
  end
end
