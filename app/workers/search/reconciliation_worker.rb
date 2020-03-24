# This worker records the number of records in an Elasticsearch index and the
# database to Datadog for comparison.
#
# For indexes that don't match a single model (no model or multiple models) we
# need to implement a custom db_count method on the Search class to do the
# counts for us
module Search
  class ReconciliationWorker
    include Sidekiq::Worker

    sidekiq_options queue: :low_priority, retry: 5

    def perform(search_class)
      search_class = search_class.constantize

      db_count = db_count(search_class)
      index_count = Search::Client.count(index: search_class::INDEX_ALIAS).dig("count")

      DatadogStatsClient.increment("elasticsearch", tags: {
                                     search_class: search_class,
                                     db_count: db_count,
                                     index_count: index_count,
                                     action: "search_reconciliation"
                                   })
    end

    private

    def db_count(search_class)
      model = search_class.to_s.demodulize.safe_constantize

      return model.estimated_count if model.respond_to?(:estimated_count) && model&.estimated_count

      return model.count if model&.count

      search_class.db_count
    end
  end
end
