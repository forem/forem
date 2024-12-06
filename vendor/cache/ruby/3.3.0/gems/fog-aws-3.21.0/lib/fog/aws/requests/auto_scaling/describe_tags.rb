module Fog
  module AWS
    class AutoScaling
      class Real
        require 'fog/aws/parsers/auto_scaling/describe_tags'

        # Lists the Auto Scaling group tags.
        #
        # ==== Parameters
        # * options<~Hash>:
        #   * tag<~Hash>:
        #     * Key<~String> - The key of the tag.
        #     * PropagateAtLaunch<~Boolean> - Specifies whether the new tag
        #       will be applied to instances launched after the tag is created.
        #       The same behavior applies to updates: If you change a tag,
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
        #     * 'DescribeTagsResult'<~Hash>:
        #       * 'NextToken'<~String> - A string used to mark the start of the
        #         next batch of returned results.
        #       * 'Tags'<~Hash>:
        #         * tagDescription<~Hash>:
        #           * 'Key'<~String> - The key of the tag.
        #           * 'PropagateAtLaunch'<~Boolean> - Specifies whether the new
        #             tag will be applied to instances launched after the tag
        #             is created. The same behavior applies to updates: If you
        #             change a tag, the changed tag will be applied to all
        #             instances launched after you made the change.
        #           * 'ResourceId'<~String> - The name of the Auto Scaling
        #             group.
        #           * 'ResourceType'<~String> - The kind of resource to which
        #             the tag is applied. Currently, Auto Scaling supports the
        #             auto-scaling-group resource type.
        #           * 'Value'<~String> - The value of the tag.
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DescribeTags.html
        #
        def describe_tags(options={})
          if filters = options.delete('Filters')
            options.merge!(Fog::AWS.indexed_filters(filters))
          end
          request({
            'Action' => 'DescribeTags',
            :parser  => Fog::Parsers::AWS::AutoScaling::DescribeTags.new
          }.merge!(options))
        end
      end

      class Mock
        def describe_tags(options={})
          raise Fog::Mock::NotImplementedError
        end
      end
    end
  end
end
