# This worker checks the number of records for each Elasticsearch index and
# compares it to the number of records in our database.
#
# For indexes that don't match a single model (no model or multiple models) we
# need to implement a custom db_count method on the Search class to do the
# counts for us
module Search
  class ReconciliationWorker
    include Sidekiq::Worker

    sidekiq_options queue: :low_priority, retry: 5

    # Once the Elasticsearch migration is complete we can update this value to
    # Search::Cluster::SEARCH_CLASSES which will include all indexes.
    SEARCH_CLASSES = [
      Search::ChatChannelMembership,
      Search::ClassifiedListing,
      Search::Tag,
    ].freeze

    # Adjustable margin of error - this is how far off the index count can be
    # from the database count before we raise an error
    def perform(margin_of_error = 0)
      SEARCH_CLASSES.each do |search_class|
        margin_of_error = margin_of_error.to_i
        db_count = db_count(search_class)
        index_count = Search::Client.count(index: search_class::INDEX_ALIAS).dig("count")
        record_difference = (db_count - index_count).abs

        tags = {
          search_class: search_class,
          db_count: db_count,
          index_count: index_count,
          record_difference: record_difference,
          margin_of_error: margin_of_error,
          action: "record_count"
        }

        if record_difference > margin_of_error
          tags[:record_count] = "mismatch"
          DatadogStatsClient.increment("elasticsearch", tags: tags)

          # This will force the job to retry
          raise DbAndEsRecordsCountMismatch, "#{search_class} record count mismatch"
        else
          tags[:record_count] = "match"
          DatadogStatsClient.increment("elasticsearch", tags: tags)
        end
      end
    end

    class DbAndEsRecordsCountMismatch < StandardError; end

    private

    def db_count(search_class)
      model = search_class.to_s.split("::").last.safe_constantize

      return model.count if model.respond_to?(:count)

      search_class.db_count
    end
  end
end
