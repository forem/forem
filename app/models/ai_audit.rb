class AiAudit < ApplicationRecord
  belongs_to :affected_user, class_name: "User", optional: true
  belongs_to :affected_content, polymorphic: true, optional: true

  def self.fast_trim_old_audits(trim_before_timestamp = ENV.fetch("FAST_TRIM_AI_AUDITS_DAYS", 30).to_i.days.ago)
    where("created_at < ?", trim_before_timestamp)
      .where("request_body != '{}'::jsonb OR response_body != '{}'::jsonb")
      .in_batches(of: 10_000).update_all(request_body: "{}", response_body: "{}")
  end
end
