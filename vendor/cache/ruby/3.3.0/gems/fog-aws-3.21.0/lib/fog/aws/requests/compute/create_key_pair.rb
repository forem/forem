module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/create_key_pair'

        # Create a new key pair
        #
        # ==== Parameters
        # * key_name<~String> - Unique name for key pair.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'keyFingerprint'<~String> - SHA-1 digest of DER encoded private key
        #     * 'keyMaterial'<~String> - Unencrypted encoded PEM private key
        #     * 'keyName'<~String> - Name of key
        #     * 'requestId'<~String> - Id of request
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateKeyPair.html]
        def create_key_pair(key_name)
          request(
            'Action'  => 'CreateKeyPair',
            'KeyName' => key_name,
            :parser   => Fog::Parsers::AWS::Compute::CreateKeyPair.new
          )
        end
      end

      class Mock
        def create_key_pair(key_name)
          response = Excon::Response.new
          unless self.data[:key_pairs][key_name]
            response.status = 200
            data = {
              'keyFingerprint'  => Fog::AWS::Mock.key_fingerprint,
              'keyMaterial'     => Fog::AWS::Mock.key_material,
              'keyName'         => key_name
            }
            self.data[:key_pairs][key_name] = data
            response.body = {
              'requestId' => Fog::AWS::Mock.request_id
            }.merge!(data)
            response
          else
            raise Fog::AWS::Compute::Error.new("InvalidKeyPair.Duplicate => The keypair '#{key_name}' already exists.")
          end
        end
      end
    end
  end
end
