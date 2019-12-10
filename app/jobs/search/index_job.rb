module Search
  class IndexJob < ApplicationJob
    queue_as :search_index

    def perform(record_type, record_id)
      return unless %w[Comment Article User].include?(record_type)

      record = record_type.constantize.find_by(id: record_id)
      return unless record

      AlgoliaSearch::AlgoliaJob.perform_later(record, "index!")
    end
  end
end
