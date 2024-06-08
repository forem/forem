module AlgoliaSearchable
  module SearchableOrganization
    extend ActiveSupport::Concern

    included do
      algoliasearch(**DEFAULT_ALGOLIA_SETTINGS) do
        attribute :name, :tag_line, :summary, :slug
        attribute :profile_image do
          { url: profile_image_90 }
        end

        add_attribute(:timestamp) { created_at.to_i }
        add_replica("Organization_timestamp_desc", per_environment: true) { customRanking ["desc(timestamp)"] }
        add_replica("Organization_timestamp_asc", per_environment: true) { customRanking ["asc(timestamp)"] }
      end
    end

    class_methods do
      def trigger_sidekiq_worker(record, delete)
        AlgoliaSearch::SearchIndexWorker.perform_async(record.class.name, record.id, delete)
      end
    end
  end
end
