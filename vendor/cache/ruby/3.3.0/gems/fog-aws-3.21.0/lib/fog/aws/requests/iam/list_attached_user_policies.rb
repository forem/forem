module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/list_managed_policies'

        # Attaches a managed policy to a user
        #
        # ==== Parameters
        # * user_name<~String>: name of the user
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
        # http://docs.aws.amazon.com/IAM/latest/APIReference/API_AttachUserPolicy.html
        #
        def list_attached_user_policies(user_name, options={})
          request({
            'Action'   => 'ListAttachedUserPolicies',
            'UserName' => user_name,
            :parser    => Fog::Parsers::AWS::IAM::ListManagedPolicies.new
          }.merge(options))
        end
      end

      class Mock
        def list_attached_user_policies(user_name, options={})
          unless self.data[:users].key?(user_name)
            raise Fog::AWS::IAM::NotFound.new("The user with name #{user_name} cannot be found.")
          end

          limit  = options['MaxItems']
          marker = options['Marker']
          user   = self.data[:users][user_name]

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
                       user[:attached_policies].map { |arn|
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
            'RequestId'   => Fog::AWS::Mock.request_id,
            'Marker'      => nil
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
