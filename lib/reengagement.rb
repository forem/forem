module Reengagement
  module_function

  # Insert eligible dormant+emailed recipients for a campaign. Idempotent.
  def build_cohort(campaign_key:, inactive_before: 2.years.ago)
    sql = <<~SQL.squish
      INSERT INTO email_reengagement_recipients (user_id, campaign_key, created_at, updated_at)
      SELECT u.id, :campaign_key, NOW(), NOW()
      FROM users u
      WHERE u.registered = true
        AND COALESCE(u.email, '') <> ''
        AND u.type_of = 0
        AND GREATEST(
              COALESCE(u.last_sign_in_at,  'epoch'),
              COALESCE(u.last_presence_at, 'epoch'),
              COALESCE(u.last_comment_at,  'epoch'),
              COALESCE(u.last_reacted_at,  'epoch'),
              COALESCE(u.last_article_at,  'epoch')
            ) < :inactive_before
        AND EXISTS (SELECT 1 FROM ahoy_messages a WHERE a.user_id = u.id)
        AND NOT EXISTS (
              SELECT 1 FROM users_roles ur JOIN roles r ON r.id = ur.role_id
              WHERE ur.user_id = u.id AND r.name IN ('spam','suspended'))
        AND NOT EXISTS (SELECT 1 FROM banished_users b WHERE b.username = u.username)
      ON CONFLICT (user_id, campaign_key) DO NOTHING
    SQL

    bind = ActiveRecord::Base.sanitize_sql_array(
      [sql, { campaign_key: campaign_key, inactive_before: inactive_before }],
    )
    ActiveRecord::Base.connection.exec_update(bind)
    EmailReengagementRecipient.for_campaign(campaign_key).count
  end
end
