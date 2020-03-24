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

    # search_class - a Search module to check the counts for
    #
    # margin_of_error - (Integer/Float) Defaults to 0. This defines how far off
    # the counts can be before an error is raised. This can be a number greater
    # than 1 to denote a count of records. If this value is less than 1, it
    # will be treated as a percentage (i.e. 0.10 is 10%).
    #
    # use_estimate_count - (Boolean) Defaults to false. If true it will use
    # ApplicationRecord.estimated_count instead of Model.count.
    def perform(search_class, margin_of_error = 0, use_estimated_count = false)
      search_class = search_class.constantize

      db_count = db_count(search_class, use_estimated_count)
      index_count = Search::Client.count(index: search_class::INDEX_ALIAS).dig("count")
      record_difference = (db_count - index_count).abs
      percentage_difference = (record_difference / db_count.to_f).round(2)

      tags = {
        search_class: search_class,
        db_count: db_count,
        index_count: index_count,
        record_difference: record_difference,
        percentage_difference: percentage_difference,
        margin_of_error: margin_of_error,
        action: "record_count"
      }

      is_count_mismatched =
        if margin_of_error > 0.0 && margin_of_error < 1.0
          percentage_difference > margin_of_error
        else
          record_difference > margin_of_error
        end

      if is_count_mismatched
        tags[:record_count] = "mismatch"
        DatadogStatsClient.increment("elasticsearch", tags: tags)

        # This will force the job to retry
        raise ReconciliationMismatch, "#{search_class} record count mismatch"
      else
        tags[:record_count] = "match"
        DatadogStatsClient.increment("elasticsearch", tags: tags)
      end
    end

    class ReconciliationMismatch < StandardError; end

    private

    def db_count(search_class, use_estimated_count)
      model = search_class.to_s.demodulize.safe_constantize

      return model.estimated_count if use_estimated_count && model.respond_to?(:estimated_count)

      return model.count if model.respond_to?(:count)

      search_class.db_count
    end
  end
end
