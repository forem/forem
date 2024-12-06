module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/list_roles'

        # Lists roles
        #
        # ==== Parameters
        # * options<~Hash>:
        #   * 'Marker'<~String>: used to paginate subsequent requests
        #   * 'MaxItems'<~Integer>: limit results to this number per page
        #   * 'PathPrefix'<~String>: prefix for filtering results
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * Roles<~Array> -
        #       role<~Hash>:
        #         * 'Arn'<~String> -
        #         * 'AssumeRolePolicyDocument'<~String<
        #         * 'Path'<~String> -
        #         * 'RoleId'<~String> -
        #         * 'RoleName'<~String> -
        #     * 'IsTruncated<~Boolean> - Whether or not results were truncated
        #     * 'Marker'<~String> - appears when IsTruncated is true as the next marker to use
        #     * 'RequestId'<~String> - Id of the request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/API_ListRoles.html
        #
        def list_roles(options={})
          request({
            'Action'    => 'ListRoles',
            :parser     => Fog::Parsers::AWS::IAM::ListRoles.new
          }.merge!(options))
        end
      end

      class Mock
        def list_roles(options={})
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
                       data[:roles].map { |role, data|
                         {
                           'Arn'                      => data[:arn].strip,
                           'AssumeRolePolicyDocument' => Fog::JSON.encode(data[:assume_role_policy_document]),
                           'RoleId'                   => data[:role_id],
                           'Path'                     => data[:path],
                           'RoleName'                 => role,
                           'CreateDate'               => data[:create_date],
                         }
                       }
                     end

          data = data_set.slice!(0, limit || 100)
          truncated = data_set.size > 0
          marker = truncated && Base64.encode64("metadata/l/#{account_id}/#{UUID.uuid}")

          response = Excon::Response.new

          body = {
            'Roles'       => data,
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
