-- This is just a test (in draft) file so that Arit and Ridhwana can work together using revision control
-- We run the contents of this file in the rails dbconsole
-- It will not be committed to the codebase, it will be moved into a data update script and this file will be deleted :)

BEGIN TRANSACTION;
WITH notification_settings_data AS (
  SELECT
    users.id AS user_id,
    COALESCE(email_badge_notifications, true),
    COALESCE(email_comment_notifications, true),
    COALESCE(email_community_mod_newsletter, false),
    COALESCE(email_connect_messages, true),
    COALESCE(email_digest_periodic, false),
    COALESCE(email_follower_notifications, true),
    COALESCE(email_mention_notifications, true),
    COALESCE(email_newsletter, false),
    COALESCE(email_tag_mod_newsletter, false),
    COALESCE(email_unread_notifications, true),
    COALESCE(mobile_comment_notifications, true),
    COALESCE(mod_roundrobin_notifications, true),
    COALESCE(reaction_notifications, true),
    COALESCE(welcome_notifications, true)
  FROM users
)
INSERT INTO users_notification_settings (user_id, email_badge_notifications, email_comment_notifications, email_community_mod_newsletter, email_connect_messages, email_digest_periodic, email_follower_notifications, email_mention_notifications, email_newsletter, email_tag_mod_newsletter, email_unread_notifications, mobile_comment_notifications, mod_roundrobin_notifications, reaction_notifications, welcome_notifications)
  SELECT * FROM notification_settings_data
  ON CONFLICT (user_id) DO UPDATE
    SET email_badge_notifications = EXCLUDED.email_badge_notifications,
        email_comment_notifications = EXCLUDED.email_comment_notifications,
        email_community_mod_newsletter = EXCLUDED.email_community_mod_newsletter,
        email_connect_messages = EXCLUDED.email_connect_messages,
        email_digest_periodic = EXCLUDED.email_digest_periodic,
        email_follower_notifications = EXCLUDED.email_follower_notifications,
        email_mention_notifications = EXCLUDED.email_mention_notifications,
        email_newsletter = EXCLUDED.email_newsletter,
        email_tag_mod_newsletter = EXCLUDED.email_tag_mod_newsletter,
        email_unread_notifications = EXCLUDED.email_unread_notifications,
        mobile_comment_notifications = EXCLUDED.mobile_comment_notifications,
        mod_roundrobin_notifications = EXCLUDED.mod_roundrobin_notifications,
        reaction_notifications = EXCLUDED.reaction_notifications,
        welcome_notifications = EXCLUDED.welcome_notifications;
COMMIT;
