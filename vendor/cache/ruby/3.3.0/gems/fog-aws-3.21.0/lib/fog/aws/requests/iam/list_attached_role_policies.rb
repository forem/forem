module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/list_managed_policies'

        # Lists managed role policies
        #
        # ==== Parameters
        # * role_name<~String>: name of the role
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'RequestId'<~String> - Id of the request
        #     * AttachedPolicies
        #       * 'PolicyArn'<~String> - The Amazon Resource Name (ARN). ARNs are unique identifiers for AWS resources.
        #       * 'PolicName'<~String> - The friendly name of the attached policy.
        #
        # ==== See Also
        # https://docs.aws.amazon.com/IAM/latest/APIReference/API_ListAttachedRolePolicies.html
        #
        def list_attached_role_policies(role_name, options={})
          request({
            'Action'   => 'ListAttachedRolePolicies',
            'RoleName' => role_name,
            :parser    => Fog::Parsers::AWS::IAM::ListManagedPolicies.new
          }.merge(options))
        end
      end

      class Mock
        def list_attached_role_policies(role_name, options={})
          unless self.data[:roles].key?(role_name)
            raise Fog::AWS::IAM::NotFound.new("The role with name #{role_name} cannot be found.")
          end

          limit  = options['MaxItems']
          marker = options['Marker']
          role   = self.data[:roles][role_name]

          if limit
            if limit > 1_000
              raise Fog::AWS::IAM::Error.new(
                "ValidationError => 1 validation error detected: Value '#{limit}' at 'limit' failed to satisfy constraint: Member must have value less than or equal to 1000"
              )
            elsif limit <  1
              raise Fog::AWS::IAM::Error.new(
                "ValidationError => 1 validation error detected: Value '#{limit}' at 'limit' failed to satisfy constraint: Member must have value greater than or equal to 1"
              )
            end
          end

          data_set = if marker
                       self.data[:markers][marker] || []
                     else
                       role[:attached_policies].map { |arn|
                         self.data[:managed_policies].fetch(arn)
                       }.map { |mp|
                         { "PolicyName" => mp.fetch("PolicyName"), "PolicyArn" => mp.fetch("Arn") }
                       }
                     end

          data = data_set.slice!(0, limit || 100)
          truncated = data_set.size > 0
          marker = truncated && Base64.encode64("metadata/l/#{account_id}/#{UUID.uuid}")

          response = Excon::Response.new

          body = {
            'Policies'    => data,
            'IsTruncated' => truncated,
            'RequestId'   => Fog::AWS::Mock.request_id
          }

          if marker
            self.data[:markers][marker] = data_set
            body.merge!('Marker' => marker)
          end

          response.body = body
          response.status = 200

          response
        end
      end
    end
  end
end
