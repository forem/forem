module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/list_signing_certificates'

        # List signing certificates for user (by default detects user from access credentials)
        #
        # ==== Parameters
        # * options<~Hash>:
        #   * 'UserName'<~String> - name of the user to list certificates for (do not include path)
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'SigningCertificates'<~Array> - Matching signing certificates
        #       * signing_certificate<~Hash>:
        #         * CertificateId<~String> -
        #         * Status<~String> -
        #       * 'IsTruncated'<~Boolean> - Whether or not the results were truncated
        #       * 'Marker'<~String> - appears when IsTruncated is true as the next marker to use
        #       * 'RequestId'<~String> - Id of the request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/index.html?API_ListSigningCertificates.html
        #
        def list_signing_certificates(options = {})
          request({
            'Action'  => 'ListSigningCertificates',
            :parser   => Fog::Parsers::AWS::IAM::ListSigningCertificates.new
          }.merge!(options))
        end
      end
    end
  end
end
