module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/basic'

        # Update an access key for a user
        #
        # ==== Parameters
        # * access_key_id<~String> - Access key id to delete
        # * status<~String> - status of keys in ['Active', 'Inactive']
        # * options<~Hash>:
        #   * 'UserName'<~String> - name of the user to create (do not include path)
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'RequestId'<~String> - Id of the request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/API_UpdateAccessKey.html
        #
        def update_access_key(access_key_id, status, options = {})
          request({
            'AccessKeyId' => access_key_id,
            'Action'      => 'UpdateAccessKey',
            'Status'      => status,
            :parser       => Fog::Parsers::AWS::IAM::Basic.new
          }.merge!(options))
        end
      end

      class Mock
        def update_access_key(access_key_id, status, options = {})
          if user = options['UserName']
            if data[:users].key? user
              access_keys_data = data[:users][user][:access_keys]
            else
              raise Fog::AWS::IAM::NotFound.new('The user with name #{user_name} cannot be found.')
            end
          else
            access_keys_data = data[:access_keys]
          end
          key = access_keys_data.find{|k| k["AccessKeyId"] == access_key_id}
          key["Status"] = status
          Excon::Response.new.tap do |response|
            response.status = 200
            response.body = { 'AccessKey' => key,
                              'RequestId' => Fog::AWS::Mock.request_id }
          end
        end
      end
    end
  end
end
