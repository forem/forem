module Search
  class IndexWorker
    include Sidekiq::Worker

    sidekiq_options queue: :default, retry: 10

    def perform(record_type, record_id)
      raise InvalidRecordType unless %w[Comment Article User PageView].include?(record_type)

      record = record_type.constantize.find_by(id: record_id)
      return unless record

      record.index!
    end
  end

  class InvalidRecordType < StandardError; end
end
