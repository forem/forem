module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/describe_images'

        # Describe all or specified images.
        #
        # ==== Params
        # * filters<~Hash> - List of filters to limit results with
        #   * filters and/or the following
        #   * 'ExecutableBy'<~String> - Only return images that the executable_by
        #     user has explicit permission to launch
        #   * 'ImageId'<~Array> - Ids of images to describe
        #   * 'Owner'<~String> - Only return images belonging to owner.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - Id of request
        #     * 'imagesSet'<~Array>:
        #       * 'architecture'<~String> - Architecture of the image
        #       * 'blockDeviceMapping'<~Array> - An array of mapped block devices
        #       * 'description'<~String> - Description of image
        #       * 'imageId'<~String> - Id of the image
        #       * 'imageLocation'<~String> - Location of the image
        #       * 'imageOwnerAlias'<~String> - Alias of the owner of the image
        #       * 'imageOwnerId'<~String> - Id of the owner of the image
        #       * 'imageState'<~String> - State of the image
        #       * 'imageType'<~String> - Type of the image
        #       * 'isPublic'<~Boolean> - Whether or not the image is public
        #       * 'kernelId'<~String> - Kernel id associated with image, if any
        #       * 'platform'<~String> - Operating platform of the image
        #       * 'productCodes'<~Array> - Product codes for the image
        #       * 'ramdiskId'<~String> - Ramdisk id associated with image, if any
        #       * 'rootDeviceName'<~String> - Root device name, e.g. /dev/sda1
        #       * 'rootDeviceType'<~String> - Root device type, ebs or instance-store
        #       * 'virtualizationType'<~String> - Type of virtualization
        #       * 'creationDate'time<~Datetime> - Date and time the image was created
        #       * 'enaSupport'<~Boolean> - whether or not the image supports enhanced networking
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeImages.html]
        def describe_images(filters = {})
          options = {}
          for key in ['ExecutableBy', 'ImageId', 'Owner']
            if filters.is_a?(Hash) && filters.key?(key)
              options.merge!(Fog::AWS.indexed_request_param(key, filters.delete(key)))
            end
          end
          params = Fog::AWS.indexed_filters(filters).merge!(options)
          request({
            'Action'    => 'DescribeImages',
            :idempotent => true,
            :parser     => Fog::Parsers::AWS::Compute::DescribeImages.new
          }.merge!(params))
        end
      end

      class Mock
        def describe_images(filters = {})
          unless filters.is_a?(Hash)
            Fog::Logger.deprecation("describe_images with #{filters.class} param is deprecated, use describe_images('image-id' => []) instead [light_black](#{caller.first})[/]")
            filters = {'image-id' => [*filters]}
          end

          if filters.keys.any? {|key| key =~ /^block-device/}
            Fog::Logger.warning("describe_images block-device-mapping filters are not yet mocked [light_black](#{caller.first})[/]")
            Fog::Mock.not_implemented
          end

          if owner = filters.delete('Owner')
            if owner == 'self'
              filters['owner-id'] = self.data[:owner_id]
            else
              filters['owner-alias'] = owner
            end
          end

          response = Excon::Response.new

          aliases = {
            'architecture'        => 'architecture',
            'description'         => 'description',
            'hypervisor'          => 'hypervisor',
            'image-id'            => 'imageId',
            'image-type'          => 'imageType',
            'is-public'           => 'isPublic',
            'kernel-id'           => 'kernelId',
            'manifest-location'   => 'manifestLocation',
            'name'                => 'name',
            'owner-alias'         => 'imageOwnerAlias',
            'owner-id'            => 'imageOwnerId',
            'ramdisk-id'          => 'ramdiskId',
            'root-device-name'    => 'rootDeviceName',
            'root-device-type'    => 'rootDeviceType',
            'state'               => 'imageState',
            'virtualization-type' => 'virtualizationType'
          }

          image_set = visible_images.values
          image_set = apply_tag_filters(image_set, filters, 'imageId')

          for filter_key, filter_value in filters
            aliased_key = aliases[filter_key]
            image_set = image_set.reject{|image| ![*filter_value].include?(image[aliased_key])}
          end

          image_set = image_set.map do |image|
            case image['imageState']
            when 'pending'
              if Time.now - image['registered'] >= Fog::Mock.delay
                image['imageState'] = 'available'
              end
            end
            image.reject { |key, value| ['registered'].include?(key) }.merge('tagSet' => self.data[:tag_sets][image['imageId']])
          end

          response.status = 200
          response.body = {
            'requestId' => Fog::AWS::Mock.request_id,
            'imagesSet' => image_set
          }
          response
        end
      end
    end
  end
end
