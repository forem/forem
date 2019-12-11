module Search
  class IndexJob < ApplicationJob
    queue_as :search_index

    def perform(record_type, record_id)
      raise InvalidRecordType unless %w[Comment Article User].include?(record_type)

      record = record_type.constantize.find_by(id: record_id)
      return unless record

      record.index!
    end
  end

  class InvalidRecordType < StandardError; end
end
