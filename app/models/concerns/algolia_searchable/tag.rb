module AlgoliaSearchable
  module Tag
    extend ActiveSupport::Concern

    included do
      include AlgoliaSearch

      algoliasearch per_environment: true, enqueue: :trigger_sidekiq_worker do
        attribute :name, :pretty_name, :short_summary, :hotness_score

        # TODO: verify if this ranking is preferred
        customRanking ["desc(hotness_score)"]
      end
    end

    class_methods do
      def trigger_sidekiq_worker(record, delete)
        AlgoliaSearch::IndexWorker.perform_async(record.class.name, record.id, delete)
      end
    end
  end
end
