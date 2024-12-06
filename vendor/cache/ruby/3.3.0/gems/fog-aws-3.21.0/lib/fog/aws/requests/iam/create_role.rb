module Fog
  module AWS
    class IAM
        # At the moment this is the only policy you can use
        EC2_ASSUME_ROLE_POLICY = <<-JSON
{
  "Version":"2008-10-17",
  "Statement":[
      {
        "Effect":"Allow",
        "Principal":{
          "Service":["ec2.amazonaws.com"]
        },
        "Action":["sts:AssumeRole"]
      }
  ]
}
        JSON

      class Real
        require 'fog/aws/parsers/iam/single_role'

        # Creates a new role for your AWS account
        #
        # ==== Parameters
        # * RoleName<~String>: name of the role to create
        # * AssumeRolePolicyDocument<~String>: The policy that grants an entity permission to assume the role.
        # * Path<~String>: This parameter is optional. If it is not included, it defaults to a slash (/).
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'Role'<~Hash>:
        #       * 'Arn'<~String> -
        #       * 'AssumeRolePolicyDocument'<~String<
        #       * 'Path'<~String> -
        #       * 'RoleId'<~String> -
        #       * 'RoleName'<~String> -
        #     * 'RequestId'<~String> - Id of the request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/API_CreateRole.html
        #
        def create_role(role_name, assume_role_policy_document, path = '/')
          request(
            'Action'                   => 'CreateRole',
            'RoleName'                 => role_name,
            'AssumeRolePolicyDocument' => assume_role_policy_document,
            'Path'                     => path,
            :parser                    => Fog::Parsers::AWS::IAM::SingleRole.new
          )
        end
      end

      class Mock
        def create_role(role_name, assume_role_policy_document, path = '/')
          if data[:roles].key?(role_name)
            raise Fog::AWS::IAM::EntityAlreadyExists.new("Role with name #{role_name} already exists")
          else
            data[:roles][role_name][:path] = path
            Excon::Response.new.tap do |response|
              response.body = {
                'Role' => {
                  'Arn'                      => data[:roles][role_name][:arn].strip,
                  'AssumeRolePolicyDocument' => Fog::JSON.encode(data[:roles][role_name][:assume_role_policy_document]),
                  'CreateDate'               => data[:roles][role_name][:create_date],
                  'Path'                     => path || "/",
                  'RoleId'                   => data[:roles][role_name][:role_id].strip,
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
end
