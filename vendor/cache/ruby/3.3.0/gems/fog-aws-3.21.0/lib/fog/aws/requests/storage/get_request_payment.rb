module Fog
  module AWS
    class Storage
      class Real
        require 'fog/aws/parsers/storage/get_request_payment'

        # Get configured payer for an S3 bucket
        #
        # @param bucket_name [String] name of bucket to get payer for
        #
        # @return [Excon::Response] response:
        #   * body [Hash]:
        #     * Payer [String] - Specifies who pays for download and requests
        #
        # @see http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentGET.html

        def get_request_payment(bucket_name)
          request({
            :expects  => 200,
            :headers  => {},
            :bucket_name => bucket_name,
            :idempotent => true,
            :method   => 'GET',
            :parser   => Fog::Parsers::AWS::Storage::GetRequestPayment.new,
            :query    => {'requestPayment' => nil}
          })
        end
      end

      class Mock # :nodoc:all
        def get_request_payment(bucket_name)
          response = Excon::Response.new
          if bucket = self.data[:buckets][bucket_name]
            response.status = 200
            response.body = { 'Payer' => bucket['Payer'] }
          else
            response.status = 404
            raise(Excon::Errors.status_error({:expects => 200}, response))
          end
          response
        end
      end
    end
  end
end
