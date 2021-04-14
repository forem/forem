-- This is just a test (in draft) file so that Arit and I can work together using revision control
-- We run the contents of this file in the rails dbconsole
-- It will not be committed to the codebase, it will be moved into a data update script and this file will be deleted :)

BEGIN TRANSACTION;
WITH settings_data AS (
    SELECT
      users.id AS user_id,
      CASE WHEN config_font='default' THEN 1
           ELSE 1
      END
      config_font,
      CASE WHEN config_navbar='default' THEN 1
           ELSE 1
      END
      config_navbar,
      CASE WHEN config_theme='default' THEN 1
           ELSE 1
      END
      config_theme,
      created_at,
      display_announcements,
      display_sponsors,
      CASE WHEN editor_version='v0' THEN 0
           WHEN editor_version='v1' THEN 1
           ELSE 0
      END
      editor_version,
      feed_mark_canonical,
      feed_referential_link,
      CASE WHEN inbox_type='private' THEN 0
           WHEN inbox_type='open' THEN 1
           ELSE 0
      END
      inbox_type,
      updated_at
    FROM users
)
INSERT INTO users_settings (user_id, config_font, config_navbar, config_theme, created_at, display_announcements, display_sponsors, editor_version, feed_mark_canonical, feed_referential_link, inbox_type, updated_at)
SELECT * from settings_data;
COMMIT;
