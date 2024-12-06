module Fog
  module AWS
    class Lambda
      class Real
        require 'fog/aws/parsers/lambda/base'

        # Returns a list of your Lambda functions.
        # http://docs.aws.amazon.com/lambda/latest/dg/API_ListFunctions.html
        # ==== Parameters
        # * Marker <~String> - opaque pagination token returned from a previous ListFunctions operation. If present, indicates where to continue the listing.
        # * MaxItems <~Integer> - Specifies the maximum number of AWS Lambda functions to return in response.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'Functions' <~Array> - list of Lambda functions.
        #     * 'NextMarker' <~String> - present if there are more functions.
        def list_functions(params={})
          request({
            :method => 'GET',
            :path   => '/functions/',
            :parser => Fog::AWS::Parsers::Lambda::Base.new
          }.merge(params))
        end
      end

      class Mock
        def list_functions(params={})
          response = Excon::Response.new
          response.status = 200
          response.body = {
            'Functions'  => self.data[:functions].values,
            'NextMarker' => nil
          }
          response
        end
      end
    end
  end
end
