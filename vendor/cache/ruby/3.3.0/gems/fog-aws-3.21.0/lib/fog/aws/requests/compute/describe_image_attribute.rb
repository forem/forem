module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/describe_image_attribute'
        # Describes an image attribute value
        #
        # ==== Parameters
        # * image_id<~String>    - The ID of the image you want to describe an attribute of
        # * attribute<~String> - The attribute to describe, must be one of the following:
        #    -'description'
        #    -'kernel'
        #    -'ramdisk'
        #    -'launchPermission'
        #    -'productCodes'
        #    -'blockDeviceMapping'
        #    -'sriovNetSupport'
        #
        # === Returns
        # * response<~Excon::Response>:
        # * body<~Hash>:
        # * 'requestId'<~String>                - Id of request
        # * 'description'<~String>           - The description for the AMI
        # * 'imageId'<~String>               - The ID of the image
        # * 'kernelId'<~String>                 - The kernel ID
        # * 'ramdiskId'<~String>                - The RAM disk ID
        # * 'blockDeviceMapping'<~List>        - The block device mapping of the image
        # * 'productCodes'<~List>               - A list of product codes
        # * 'sriovNetSupport'<~String>          - The value to use for a resource attribute
        # (Amazon API Reference)[http://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeImageAttribute.html]
        def describe_image_attribute(image_id, attribute)
          request(
            'Action'       => 'DescribeImageAttribute',
            'ImageId'   => image_id,
            'Attribute'    => attribute,
            :parser        => Fog::Parsers::AWS::Compute::DescribeImageAttribute.new
          )
        end
      end

      class Mock
        def describe_image_attribute(image_id, attribute)
          response = Excon::Response.new
          if image = self.data[:images].values.find{ |i| i['imageId'] == image_id }
            response.status = 200
            response.body = {
              'requestId' => Fog::AWS::Mock.request_id,
              'imageId'     => image_id
            }
            case attribute
            when 'kernel'
              response.body[attribute] = image["kernelId"]
            when 'ramdisk'
              response.body[attribute] = image["ramdiskId"]
            when 'sriovNetSupport'
              response.body[attribute] = 'simple'
            when 'launchPermission'
              if image_launch_permissions = self.data[:image_launch_permissions][image_id]
                response.body[attribute] = image_launch_permissions[:users]
              else
                response.body[attribute] = []
              end
            else
              response.body[attribute] = image[attribute]
            end
          response
          else
            raise Fog::AWS::Compute::NotFound.new("The Image '#{image_id}' does not exist")
          end
        end
      end
    end
  end
end
