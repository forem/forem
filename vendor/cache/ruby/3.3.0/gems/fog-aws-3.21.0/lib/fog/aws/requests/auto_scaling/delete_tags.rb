module Fog
  module AWS
    class AutoScaling
      class Real
        require 'fog/aws/parsers/auto_scaling/basic'

        # Removes the specified tags or a set of tags from a set of resources.
        #
        # ==== Parameters
        # * tags<~Array>:
        #   * tag<~Hash>:
        #     * Key<~String> - The key of the tag.
        #     * PropagateAtLaunch<~Boolean> - Specifies whether the new tag
        #       will be applied to instances launched after the tag is created.
        #       The same behavior applies to updates: If you change a tag, the
        #       changed tag will be applied to all instances launched after you
        #       made the change.
        #     * ResourceId<~String> - The name of the Auto Scaling group.
        #     * ResourceType<~String> - The kind of resource to which the tag
        #       is applied. Currently, Auto Scaling supports the
        #       auto-scaling-group resource type.
        #     * Value<~String> - The value of the tag.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DeleteTags.html
        #
        def delete_tags(tags)
          params = {}
          tags.each_with_index do |tag, i|
            tag.each do |key, value|
              params["Tags.member.#{i+1}.#{key}"] = value unless value.nil?
            end
          end
          request({
            'Action' => 'DeleteTags',
            :parser  => Fog::Parsers::AWS::AutoScaling::Basic.new
          }.merge!(params))
        end
      end

      class Mock
        def delete_tags(tags)
          if tags.to_a.empty?
            raise Fog::AWS::AutoScaling::ValidationError.new("1 validation error detected: Value null at 'tags' failed to satisfy constraint: Member must not be null")
          end
          raise Fog::Mock::NotImplementedError
        end
      end
    end
  end
end
