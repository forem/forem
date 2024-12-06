module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/upload_signing_certificate'

        # Upload signing certificate for user (by default detects user from access credentials)
        #
        # ==== Parameters
        # * options<~Hash>:
        #   * 'UserName'<~String> - name of the user to upload certificate for (do not include path)
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'Certificate'<~Hash>:
        #       * 'CertificateId'<~String> -
        #       * 'UserName'<~String> -
        #       * 'CertificateBody'<~String> -
        #       * 'Status'<~String> -
        #     * 'RequestId'<~String> - Id of the request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/index.html?API_UploadSigningCertificate.html
        #
        def upload_signing_certificate(certificate, options = {})
          request({
            'Action'          => 'UploadSigningCertificate',
            'CertificateBody' => certificate,
            :parser           => Fog::Parsers::AWS::IAM::UploadSigningCertificate.new
          }.merge!(options))
        end
      end
    end
  end
end
