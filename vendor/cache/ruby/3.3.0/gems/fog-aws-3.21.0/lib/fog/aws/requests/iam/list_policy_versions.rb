module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/list_policy_versions'

        # Lists policy versions
        #
        # ==== Parameters
        # * options <~Hash>: options that filter the result set
        #   * Marker <~String>
        #   * MaxItems <~Integer>
        #   * PolicyArn <~String>
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'RequestId'<~String> - Id of the request
        #     * 'IsTruncated'<~Boolean>
        #     * 'Marker'<~String>
        #     * 'Versions'<~Array>:
        #       * CreateDate
        #       * IsDefaultVersion
        #       * VersionId
        # ==== See Also
        # http://docs.aws.amazon.com/IAM/latest/APIReference/API_ListPolicyVersions.html
        #
        def list_policy_versions(policy_arn, options={})
          request({
            'Action'          => 'ListPolicyVersions',
            'PolicyArn'       => policy_arn,
            :parser           => Fog::Parsers::AWS::IAM::ListPolicyVersions.new
          }.merge(options))
        end
      end

      class Mock
        def list_policy_versions(policy_arn, options={})
          limit  = options['MaxItems']
          marker = options['Marker']

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
                       self.data[:policy_versions].values
                     end

          data = data_set.slice!(0, limit || 100)
          truncated = data_set.size > 0
          marker = truncated && Base64.encode64("metadata/l/#{account_id}/#{UUID.uuid}")

          response = Excon::Response.new

          body = {
            'Versions'    => data,
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
