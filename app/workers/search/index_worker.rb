module Search
  class IndexWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority, retry: 10

    VALID_RECORD_TYPES = %w[Article User].freeze

    def perform(record_type, record_id)
      unless VALID_RECORD_TYPES.include?(record_type)
        raise InvalidRecordType, "Invalid class: #{record_type}. Valid and indexable classes are #{VALID_RECORD_TYPES.join(', ')}"
      end

      record = record_type.constantize.find_by(id: record_id)
      return unless record

      record.index!
    end
  end

  class InvalidRecordType < StandardError; end
end
