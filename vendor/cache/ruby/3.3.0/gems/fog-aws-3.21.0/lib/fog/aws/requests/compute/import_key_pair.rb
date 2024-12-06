module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/import_key_pair'

        # Import an existing public key to create a new key pair
        #
        # ==== Parameters
        # * key_name<~String> - Unique name for key pair.
        # * public_key_material<~String> - RSA public key
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'keyFingerprint'<~String> - SHA-1 digest of DER encoded private key
        #     * 'keyName'<~String> - Name of key
        #     * 'requestId'<~String> - Id of request
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-ImportKeyPair.html]
        def import_key_pair(key_name, public_key_material)
          request(
            'Action'  => 'ImportKeyPair',
            'KeyName' => key_name,
            'PublicKeyMaterial' => Base64::encode64(public_key_material),
            :parser   => Fog::Parsers::AWS::Compute::ImportKeyPair.new
          )
        end
      end

      class Mock
        def import_key_pair(key_name, public_key_material)
          response = Excon::Response.new
          unless self.data[:key_pairs][key_name]
            response.status = 200
            data = {
              'keyFingerprint'  => Fog::AWS::Mock.key_fingerprint,
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
