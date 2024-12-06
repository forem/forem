module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/list_server_certificates'

        # List server certificates
        #
        # ==== Parameters
        # * options<~Hash>:
        #   * 'Marker'<~String> - The marker from the previous result (for pagination)
        #   * 'MaxItems'<~String> - The maximum number of server certificates you want in the response
        #   * 'PathPrefix'<~String> - The path prefix for filtering the results
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'Certificates'<~Array> - Matching server certificates
        #       * server_certificate<~Hash>:
        #         * Arn<~String> -
        #         * Path<~String> -
        #         * ServerCertificateId<~String> -
        #         * ServerCertificateName<~String> -
        #         * UploadDate<~Time> -
        #       * 'IsTruncated'<~Boolean> - Whether or not the results were truncated
        #       * 'Marker'<~String> - appears when IsTruncated is true as the next marker to use
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/index.html?API_ListServerCertificates.html
        #
        def list_server_certificates(options = {})
          request({
            'Action'  => 'ListServerCertificates',
            :parser   => Fog::Parsers::AWS::IAM::ListServerCertificates.new
          }.merge!(options))
        end
      end

      class Mock
        def list_server_certificates(options = {})
          certificates = self.data[:server_certificates].values
          certificates = certificates.select { |certificate| certificate['Path'] =~ Regexp.new("^#{options['PathPrefix']}") } if options['PathPrefix']
          response = Excon::Response.new
          response.status = 200
          response.body = {
            'Certificates' => certificates
          }

          response
        end
      end
    end
  end
end
