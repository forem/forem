module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/list_managed_policies'

        # Lists managed policies
        #
        # ==== Parameters
        # * options <~Hash>: options that filter the result set
        #   * Marker <~String>
        #   * MaxItems <~Integer>
        #   * OnlyAttached <~Boolean>
        #   * PathPrefix <~String>
        #   * Scope <~String>
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'RequestId'<~String> - Id of the request
        #     * 'IsTruncated'<~Boolean>
        #     * 'Marker'<~String>
        #     * 'Policies'<~Array>:
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
        # http://docs.aws.amazon.com/IAM/latest/APIReference/API_ListPolicies.html
        #
        def list_policies(options={})
          request({
            'Action'          => 'ListPolicies',
            :parser           => Fog::Parsers::AWS::IAM::ListManagedPolicies.new
          }.merge(options))
        end
      end

      class Mock
        def list_policies(options={})
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
                       self.data[:managed_policies].values
                     end

          if options["PathPrefix"]
            data_set = data_set.select { |p| p["Path"].match(/^#{options["PathPrefix"]}/) }
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
