module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/describe_tags'

        # Describe all or specified tags
        #
        # ==== Parameters
        # * filters<~Hash> - List of filters to limit results with
        #
        # === Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - Id of request
        #     * 'tagSet'<~Array>:
        #       * 'resourceId'<~String> - id of resource tag belongs to
        #       * 'resourceType'<~String> - type of resource tag belongs to
        #       * 'key'<~String> - Tag's key
        #       * 'value'<~String> - Tag's value
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeTags.html]
        def describe_tags(filters = {})
          params = Fog::AWS.indexed_filters(filters)
          request({
            'Action'    => 'DescribeTags',
            :idempotent => true,
            :parser     => Fog::Parsers::AWS::Compute::DescribeTags.new
          }.merge!(params))
        end
      end

      class Mock
        def describe_tags(filters = {})
          response = Excon::Response.new

          tag_set = deep_clone(self.data[:tags])

          aliases = {
            'key'               => 'key',
            'resource-id'       => 'resourceId',
            'resource-type'     => 'resourceType',
            'value'             => 'value'
          }

          for filter_key, filter_value in filters
            filter_attribute = aliases[filter_key]
            case filter_attribute
            when 'key'
              tag_set.reject! { |k,_| k != filter_value }
            when 'value'
              tag_set.each { |k,values| values.reject! { |v, _| v != filter_value } }
            when 'resourceId'
              filter_resources(tag_set, 'resourceId', filter_value)
            when 'resourceType'
              filter_resources(tag_set, 'resourceType', filter_value)
            end
          end

          tagged_resources = []
          tag_set.each do |key, values|
            values.each do |value, resources|
              resources.each do |resource|
                tagged_resources << resource.merge({
                  'key' => key,
                  'value' => value
                })
              end
            end
          end

          response.status = 200
          response.body = {
            'requestId'       => Fog::AWS::Mock.request_id,
            'tagSet'          => tagged_resources
          }
          response
        end

        private

          def filter_resources(tag_set, filter, value)
            value_hash_list = tag_set.values
            value_hash_list.each do |value_hash|
              value_hash.each do |_, resource_list|
                resource_list.reject! { |resource| resource[filter] != value }
              end
            end
          end

          def deep_clone(obj)
            case obj
            when Hash
              obj.reduce({}) { |h, pair| h[pair.first] = deep_clone(pair.last); h }
            when Array
              obj.map { |o| deep_clone(o) }
            else
              obj
            end
          end
      end
    end
  end
end
