module AlgoliaSearchable
  module SearchableTag
    extend ActiveSupport::Concern

    included do
      include AlgoliaSearch

      algoliasearch(**DEFAULT_ALGOLIA_SETTINGS) do
        attribute :name, :pretty_name, :short_summary, :hotness_score, :supported, :rules_html, :bg_color_hex

        attribute :badge do
          { badge_image: {
            url: if badge&.badge_image_url
                   ApplicationController.helpers.optimized_image_url(badge&.badge_image_url, width: 64)
                 end
          } }
        end

        add_attribute(:timestamp) { created_at.to_i }

        customRanking ["desc(hotness_score)"]

        add_replica("Tag_timestamp_desc", per_environment: true) { customRanking ["desc(timestamp)"] }
        add_replica("Tag_timestamp_asc", per_environment: true) { customRanking ["asc(timestamp)"] }

        attributesForFaceting ["searchable(supported)"]
      end
    end

    class_methods do
      def trigger_sidekiq_worker(record, delete)
        AlgoliaSearch::SearchIndexWorker.perform_async(record.class.name, record.id, delete)
      end
    end
  end
end
