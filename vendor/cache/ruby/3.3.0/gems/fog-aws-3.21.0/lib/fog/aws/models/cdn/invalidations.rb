require 'fog/aws/models/cdn/invalidation'

module Fog
  module AWS
    class CDN
      class Invalidations < Fog::Collection
        attribute :is_truncated,            :aliases => ['IsTruncated']
        attribute :max_items,               :aliases => ['MaxItems']
        attribute :next_marker,             :aliases => ['NextMarker']
        attribute :marker,                  :aliases => ['Marker']

        attribute :distribution

        model Fog::AWS::CDN::Invalidation

        def all(options = {})
          requires :distribution
          options[:max_items]  ||= max_items
          options.delete_if {|key, value| value.nil?}

          data = service.get_invalidation_list(distribution.identity, options).body

          merge_attributes(data.reject {|key, value| !['IsTruncated', 'MaxItems', 'NextMarker', 'Marker'].include?(key)})

          load(data['InvalidationSummary'])
        end

        def get(invalidation_id)
          requires :distribution

          data = service.get_invalidation(distribution.identity, invalidation_id).body

          if data
            invalidation = new(data)
          else
            nil
          end
        rescue Excon::Errors::NotFound
          nil
        end

        def new(attributes = {})
          requires :distribution
          super({ :distribution => distribution }.merge!(attributes))
        end
      end
    end
  end
end
