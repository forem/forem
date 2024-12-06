module Fog
  module AWS
    class IAM
      class Real
        # Update a Signing Certificate
        #
        # ==== Parameters
        # * certificate_id<~String> - Required. ID of the Certificate to update.
        # * status<~String> - Required. Active/Inactive
        # * options<~Hash>:
        #   * user_name<~String> - Name of the user the signing certificate belongs to.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'RequestId'<~String> - Id of the request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/index.html?API_UpdateSigningCertificate.html
        #
        def update_signing_certificate(certificate_id, status, options = {})
          request({
            'Action'        => 'UpdateSigningCertificate',
            'CertificateId' => certificate_id,
            'Status'        => status,
            :parser         => Fog::Parsers::AWS::IAM::Basic.new
          }.merge!(options))
        end
      end
    end
  end
end
