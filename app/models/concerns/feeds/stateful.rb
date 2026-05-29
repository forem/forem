module Feeds
  module Stateful
    extend ActiveSupport::Concern

    VALID_TRANSITIONS = {
      "pending" => %w[fetching failed],
      "fetching" => %w[parsing failed],
      "parsing" => %w[importing failed],
      "importing" => %w[completed failed],
      "completed" => [],
      "failed" => [],
    }.freeze

    included do
      validate :validate_status_transition, if: :status_changed?
    end

    def transition_to!(new_status)
      update!(status: new_status)
    end

    private

    def validate_status_transition
      return unless persisted? # skip for new records — allow factories/setup to set any initial status

      allowed = VALID_TRANSITIONS.fetch(status_was, [])
      return if allowed.include?(status)

      errors.add(:status, "cannot transition from #{status_was} to #{status}")
    end
  end
end
