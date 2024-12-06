module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/list_access_keys'

        # List access_keys
        #
        # ==== Parameters
        # * options<~Hash>:
        #   * 'Marker'<~String> - used to paginate subsequent requests
        #   * 'MaxItems'<~Integer> - limit results to this number per page
        #   * 'UserName'<~String> - optional: username to lookup access keys for, defaults to current user
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'AccessKeys'<~Array> - Matching access keys
        #       * access_key<~Hash>:
        #         * AccessKeyId<~String> -
        #         * Status<~String> -
        #     * 'IsTruncated<~Boolean> - Whether or not results were truncated
        #     * 'Marker'<~String> - appears when IsTruncated is true as the next marker to use
        #     * 'RequestId'<~String> - Id of the request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/API_ListAccessKeys.html
        #
        def list_access_keys(options = {})
          request({
            'Action'  => 'ListAccessKeys',
            :parser   => Fog::Parsers::AWS::IAM::ListAccessKeys.new
          }.merge!(options))
        end
      end

      class Mock
        def list_access_keys(options = {})
          #FIXME: Doesn't do anything with options, aside from UserName
          if user = options['UserName']
            if data[:users].key? user
              access_keys_data = data[:users][user][:access_keys]
            else
              raise Fog::AWS::IAM::NotFound.new("The user with name #{user} cannot be found.")
            end
          else
            access_keys_data = data[:access_keys]
          end

          Excon::Response.new.tap do |response|
            response.body = { 'AccessKeys' => access_keys_data.map do |akey|
                                                {'Status' => akey['Status'], 'AccessKeyId' => akey['AccessKeyId']}
                                              end,
                               'IsTruncated' => false,
                               'RequestId' => Fog::AWS::Mock.request_id }
            response.status = 200
          end
        end
      end
    end
  end
end
