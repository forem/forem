module AlgoliaSearchable
  module SearchableTag
    extend ActiveSupport::Concern

    included do
      include AlgoliaSearch

      algoliasearch(**DEFAULT_ALGOLIA_SETTINGS) do
        attribute :name, :pretty_name, :short_summary, :hotness_score

        customRanking ["desc(hotness_score)"]
      end
    end

    class_methods do
      def trigger_sidekiq_worker(record, delete)
        AlgoliaSearch::SearchIndexWorker.perform_async(record.class.name, record.id, delete)
      end
    end
  end
end
