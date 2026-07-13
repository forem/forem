# One-off re-engagement ("click to stay subscribed") campaign tasks.
# Delete this file once the campaign has completed.
#
# Flow:
#   1. rake reengagement:build_cohort
#      → builds a manual AudienceSegment of dormant-but-emailable users and
#        prints its id.
#   2. In /admin/emails, create a one-off Email targeting that segment, with a
#      "keep me subscribed" button linking to *|stay_subscribed_url|*, and
#      activate it (delivery goes through the standard custom-email pipeline).
#   3. After the response window:
#      CONFIRM=YES rake reengagement:prune[SEGMENT_ID]
namespace :reengagement do
  desc "Build a manual AudienceSegment of email-eligible users inactive for 2+ years"
  task build_cohort: :environment do
    inactive_before = Emails::ReengagementPruneWorker::INACTIVE_THRESHOLD.ago
    activity_sql = User::ACTIVITY_TIMESTAMP_KEYS.map { |key| "COALESCE(users.#{key}, 'epoch')" }.join(", ")
    segment = AudienceSegment.create!(type_of: :manual)
    scope = User.email_eligible
      .where(type_of: :member).where("GREATEST(#{activity_sql}) < ?", inactive_before)
      .where("EXISTS (SELECT 1 FROM ahoy_messages WHERE ahoy_messages.user_id = users.id)")
      .where("NOT EXISTS (SELECT 1 FROM banished_users WHERE banished_users.username = users.username)")
    inserted = 0
    scope.in_batches(of: 5000) do |batch|
      now = Time.current
      rows = batch.ids.map { |id| { audience_segment_id: segment.id, user_id: id, created_at: now, updated_at: now } }
      SegmentedUser.insert_all(rows) if rows.any?
      inserted += rows.size
    end
    puts "AudienceSegment ##{segment.id} built with #{inserted} users. Attach it to a one-off Email in /admin/emails."
  end
end

namespace :reengagement do
  desc "Unsubscribe non-responders. Usage: CONFIRM=YES rake reengagement:prune[SEGMENT_ID]"
  task :prune, [:segment_id] => :environment do |_t, args|
    abort "Refusing to prune without CONFIRM=YES" unless ENV["CONFIRM"] == "YES"
    segment = AudienceSegment.find(args.fetch(:segment_id))
    segment.segmented_users.in_batches(of: 1000) do |batch|
      Emails::ReengagementPruneWorker.perform_async(batch.pluck(:user_id))
    end
    puts "Enqueued prune for segment ##{segment.id}"
  end
end
