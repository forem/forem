module Concepts
  class ClassifyRecordWorker
    include Sidekiq::Job
    sidekiq_options queue: :low_priority, lock: :until_executing, on_conflict: :replace

    def perform(record_type, record_id)
      return unless %w[Article Comment].include?(record_type)

      klass = record_type.constantize
      record = klass.find_by(id: record_id)
      return unless record&.respond_to?(:semantic_embedding) && record.respond_to?(:concept_memberships)

      # For Articles, only classify if they are published
      if record.is_a?(Article) && !record.published?
        return
      end

      Concepts::Classifier.new(record).call
    end
  end
end
