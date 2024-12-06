module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/copy_image'

        # Copy an image to a different region
        #
        # ==== Parameters
        # * source_image_id<~String>    - The ID of the AMI to copy
        # * source_region<~String>      - The name of the AWS region that contains the AMI to be copied
        # * name<~String>               - The name of the new AMI in the destination region
        # * description<~String>        - The description to set on the new AMI in the destination region
        # * client_token<~String>       - Unique, case-sensitive identifier you provide to ensure idempotency of the request
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - id of request
        #     * 'imageId'<~String> - id of image
        #
        # {Amazon API Reference}[http://docs.aws.amazon.com/AWSEC2/latest/CommandLineReference/ApiReference-cmd-CopyImage.html]
        def copy_image(source_image_id, source_region, name = nil, description = nil, client_token = nil)
          request(
            'Action'          => 'CopyImage',
            'SourceImageId'   => source_image_id,
            'SourceRegion'    => source_region,
            'Name'            => name,
            'Description'     => description,
            'ClientToken'     => client_token,
            :parser           => Fog::Parsers::AWS::Compute::CopyImage.new
          )
        end
      end

      class Mock
        #
        # Usage
        #
        # Fog::AWS[:compute].copy_image("ami-1aad5273", 'us-east-1')
        #

        def copy_image(source_image_id, source_region, name = nil, description = nil, client_token = nil)
          response = Excon::Response.new
          response.status = 200
          image_id = Fog::AWS::Mock.image_id
          data = {
            'imageId'  => image_id,
          }
          self.data[:images][image_id] = data
          response.body = {
            'requestId' => Fog::AWS::Mock.request_id
          }.merge!(data)
          response
        end
      end
    end
  end
end
