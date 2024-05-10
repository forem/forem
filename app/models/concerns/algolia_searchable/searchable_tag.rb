module AlgoliaSearchable
  module SearchableTag
    extend ActiveSupport::Concern

    included do
      include AlgoliaSearch

      algoliasearch(**DEFAULT_ALGOLIA_SETTINGS) do
        attribute :name, :pretty_name, :short_summary, :hotness_score
        add_attribute(:timestamp) { created_at.to_i }

        customRanking ["desc(hotness_score)"]

        add_replica("Tag_timestamp_desc", per_environment: true) { customRanking ["desc(timestamp)"] }
        add_replica("Tag_timestamp_asc", per_environment: true) { customRanking ["asc(timestamp)"] }
      end
    end

    class_methods do
      def trigger_sidekiq_worker(record, delete)
        AlgoliaSearch::SearchIndexWorker.perform_async(record.class.name, record.id, delete)
      end
    end
  end
end
