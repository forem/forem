module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/single_policy'

        # Creates a managed policy
        #
        # ==== Parameters
        # * policy_name<~String>: name of policy document
        # * policy_document<~Hash>: policy document, see: http://docs.amazonwebservices.com/IAM/latest/UserGuide/PoliciesOverview.html
        # * path <~String>: path of the policy
        # * description <~String>: description for the policy
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'RequestId'<~String> - Id of the request
        #     * 'Policy'<~Hash>:
        #       * Arn
        #       * AttachmentCount
        #       * CreateDate
        #       * DefaultVersionId
        #       * Description
        #       * IsAttachable
        #       * Path
        #       * PolicyId
        #       * PolicyName
        #       * UpdateDate
        # ==== See Also
        # http://docs.aws.amazon.com/IAM/latest/APIReference/API_CreatePolicy.html
        #
        def create_policy(policy_name, policy_document, path=nil, description=nil)
          request({
            'Action'          => 'CreatePolicy',
            'PolicyName'      => policy_name,
            'PolicyDocument'  => Fog::JSON.encode(policy_document),
            'Path'            => path,
            'Description'     => description,
            :parser           => Fog::Parsers::AWS::IAM::SinglePolicy.new
          }.reject {|_, value| value.nil?})
        end
      end

      class Mock
        def create_policy(policy_name, policy_document, path="/", description=nil)
          response = Excon::Response.new

          arn = "arn:aws:iam:#{Fog::AWS::Mock.owner_id}:policy/#{policy_name}"

          policy = {
            "Arn"              => arn,
            "AttachmentCount"  => 0,
            "CreateDate"       => Time.now.utc,
            "DefaultVersionId" => "v1",
            "Description"      => description,
            "IsAttachable"     => true,
            "Path"             => path,
            "PolicyId"         => Fog::Mock.random_hex(21),
            "PolicyName"       => policy_name,
            "UpdateDate"       => Time.now.utc,
          }

          self.data[:managed_policies][arn] = policy

          response.body = {"RequestId" => Fog::AWS::Mock.request_id, "Policy" => policy}
          response
        end
      end
    end
  end
end
