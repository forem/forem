module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/get_group_policy'

        # Get Group Policy
        #
        # ==== Parameters
        # * 'PolicyName'<~String>: Name of the policy to get
        # * 'GroupName'<~String>: Name of the Group who the policy is associated with.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #       * PolicyDocument<~String> The policy document.
        #       * PolicyName<~String> The name of the policy.
        #       * GroupName<~String> The Group the policy is associated with.
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/API_GetGroupPolicy.html
        #
        def get_group_policy(policy_name, group_name)
          request({
            'Action'     => 'GetGroupPolicy',
            'PolicyName' => policy_name,
            'GroupName'  => group_name,
            :parser      => Fog::Parsers::AWS::IAM::GetGroupPolicy.new
          })
        end
      end
      class Mock
        def get_group_policy(policy_name, group_name)
          raise Fog::AWS::IAM::NotFound.new("The group with name #{group_name} cannot be found.") unless self.data[:groups].key?(group_name)
          raise Fog::AWS::IAM::NotFound.new("The policy with name #{policy_name} cannot be found.") unless self.data[:groups][group_name][:policies].key?(policy_name)
          Excon::Response.new.tap do |response|
            response.body = { 'Policy' =>  {
                                'PolicyName' => policy_name,
                                'GroupName' => group_name,
                                'PolicyDocument' => data[:groups][group_name][:policies][policy_name]
                              },
                              'IsTruncated' => false,
                              'RequestId'   => Fog::AWS::Mock.request_id
                            }
            response.status = 200
          end
        end
      end
    end
  end
end
