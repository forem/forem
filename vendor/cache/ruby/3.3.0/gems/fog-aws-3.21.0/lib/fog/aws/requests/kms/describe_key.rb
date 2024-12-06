module Fog
  module AWS
    class KMS
      class Real
        require 'fog/aws/parsers/kms/describe_key'

        def describe_key(identifier)
          request(
            'Action' => 'DescribeKey',
            'KeyId'  => identifier,
            :parser  => Fog::Parsers::AWS::KMS::DescribeKey.new
          )
        end
      end

      class Mock
        def describe_key(identifier)
          response = Excon::Response.new
          key = self.data[:keys][identifier]

          response.body = { "KeyMetadata" => key }
          response
        end
      end
    end
  end
end
