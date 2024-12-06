module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/basic'

        # Upload signing certificate for user (by default detects user from access credentials)
        #
        # ==== Parameters
        # * options<~Hash>:
        #   * 'UserName'<~String> - name of the user to upload certificate for (do not include path)
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'RequestId'<~String> - Id of the request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/index.html?API_DeleteSigningCertificate.html
        #
        def delete_signing_certificate(certificate_id, options = {})
          request({
            'Action'        => 'DeleteSigningCertificate',
            'CertificateId' => certificate_id,
            :parser         => Fog::Parsers::AWS::IAM::Basic.new
          }.merge!(options))
        end
      end
    end
  end
end
