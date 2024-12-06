module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/basic'

        # Add or update a policy for a user
        #
        # ==== Parameters
        # * user_name<~String>: name of the user
        # * policy_name<~String>: name of policy document
        # * policy_document<~Hash>: policy document, see: http://docs.amazonwebservices.com/IAM/latest/UserGuide/PoliciesOverview.html
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'RequestId'<~String> - Id of the request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/API_PutUserPolicy.html
        #
        def put_user_policy(user_name, policy_name, policy_document)
          request(
            'Action'          => 'PutUserPolicy',
            'PolicyName'      => policy_name,
            'PolicyDocument'  => Fog::JSON.encode(policy_document),
            'UserName'        => user_name,
            :parser           => Fog::Parsers::AWS::IAM::Basic.new
          )
        end
      end

      class Mock
        #FIXME: You can't actually use the credentials for anything elsewhere in Fog
        #FIXME: Doesn't do any validation on the policy
        def put_user_policy(user_name, policy_name, policy_document)
          if data[:users].key? user_name
            data[:users][user_name][:policies][policy_name] = policy_document

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
