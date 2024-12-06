module Fog
  module AWS
    class CDN
      module DistributionsHelper

        def all(options = {})
          merge_attributes(options)
          data = list_distributions(options).body
          merge_attributes('IsTruncated' => data['IsTruncated'], 'Marker' => data['Marker'], 'MaxItems' => data['MaxItems'])
          if summary = data['DistributionSummary']
            load(summary.map { |a| { 'DistributionConfig' => a } })
          else
            load((data['StreamingDistributionSummary'] || {}).map { |a| { 'StreamingDistributionConfig' => a }})
          end
        end

        def get(dist_id)
          response = get_distribution(dist_id)
          data = response.body.merge({'ETag' => response.headers['ETag']})
          new(data)
        rescue Excon::Errors::NotFound
          nil
        end

        def each_distribution
          if !block_given?
            self
          else
            subset = dup.all

            subset.each_distribution_this_page {|f| yield f}
            while subset.is_truncated
              subset = subset.all('Marker' => subset.marker, 'MaxItems' => 1000)
              subset.each_distribution_this_page {|f| yield f}
            end

            self
          end
        end
      end
    end
  end
end
