module Fog
  module AWS
    class IAM
      class PagedCollection < Fog::Collection
        def self.inherited(klass)
          klass.send(:attribute, :truncated, :aliases => 'IsTruncated', :type => :boolean)
          klass.send(:attribute, :marker,    :aliases => 'Marker')

          super
        end

        def each_entry(*args, &block)
          to_a.each(*args, &block)
        end

        def each(options={})
          limit = options[:limit] || 100

          if !block_given?
            self
          else
            subset = dup.all

            subset.each_entry { |f| yield f }

            while subset.truncated
              subset.
                all(:marker => subset.marker, :limit => limit).
                each_entry { |f| yield f }
            end

            self
          end
        end

        protected

        def page_params(options={})
          marker = options.fetch(:marker) { options.fetch('Marker') { self.marker } }
          limit  = options.fetch(:limit) { options['MaxItems'] }
          params = {}

          if marker && !marker.empty?
            params.merge!('Marker' => marker)
          end

          if limit
            params.merge!('MaxItems' => limit)
          end

          params
        end
      end
    end
  end
end
