module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/basic'

        # Delete an access key
        #
        # ==== Parameters
        # * access_key_id<~String> - Access key id to delete
        # * options<~Hash>:
        #   * 'UserName'<~String> - name of the user to create (do not include path)
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'RequestId'<~String> - Id of the request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/API_DeleteAccessKey.html
        #
        def delete_access_key(access_key_id, options = {})
          request({
            'AccessKeyId' => access_key_id,
            'Action'      => 'DeleteAccessKey',
            :parser       => Fog::Parsers::AWS::IAM::Basic.new
          }.merge!(options))
        end
      end

      class Mock
        def delete_access_key(access_key_id, options = {})
          user_name = options['UserName']
          if user_name && data[:users].key?(user_name) && data[:users][user_name][:access_keys].any? { |akey| akey['AccessKeyId'] == access_key_id }
            data[:users][user_name][:access_keys].delete_if { |akey| akey['AccessKeyId'] == access_key_id }
            Excon::Response.new.tap do |response|
              response.body = { 'RequestId' => Fog::AWS::Mock.request_id }
              response.status = 200
            end
          else
            raise Fog::AWS::IAM::NotFound.new("The Access Key with id #{access_key_id} cannot be found.")
          end
        end
      end
    end
  end
end
