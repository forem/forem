module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/upload_server_certificate'

        # Gets the specified server certificate.
        #
        # ==== Parameters
        # * server_certificate_name<~String>: The name of the server certificate you want to get.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'RequestId'<~String> - Id of the request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/API_GetServerCertificate.html
        #
        def get_server_certificate(name)
          request({
            'Action'                => 'GetServerCertificate',
            'ServerCertificateName' => name,
            :parser                 => Fog::Parsers::AWS::IAM::UploadServerCertificate.new
          })
        end
      end

      class Mock
        def get_server_certificate(name)
          raise Fog::AWS::IAM::NotFound unless certificate = self.data[:server_certificates][name]

          response = Excon::Response.new
          response.status = 200
          response.body = {
            'Certificate' => certificate,
            'RequestId' => Fog::AWS::Mock.request_id
          }

          response
        end
      end
    end
  end
end
