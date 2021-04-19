-- This is just a test (in draft) file so that Arit and I can work together using revision control
-- We run the contents of this file in the rails dbconsole
-- It will not be committed to the codebase, it will be moved into a data update script and this file will be deleted :)

BEGIN TRANSACTION;
WITH settings_data AS (
  SELECT
    users.id AS user_id,
    CASE WHEN config_font='default' THEN 0
         WHEN config_font='comic_sans' THEN 1
         WHEN config_font='monospace' THEN 2
         WHEN config_font='open_dyslexic' THEN 3
         WHEN config_font='sans_serif' THEN 4
         WHEN config_font='serif' THEN 5
         ELSE 0
    END
    config_font,
    CASE WHEN config_navbar='default_navbar' THEN 0
         WHEN config_navbar='static_navbar' THEN 1
         ELSE 0
    END
    config_navbar,
    CASE WHEN config_theme='default_theme' THEN 0
         WHEN config_theme='minimal_light_theme' THEN 1
         WHEN config_theme='night_theme' THEN 2
         WHEN config_theme='pink_theme' THEN 3
         WHEN config_theme='ten_x_hacker_theme' THEN 4
         ELSE 0
    END
    config_theme,
    CASE WHEN editor_version='v2' THEN 0
          WHEN editor_version='v1' THEN 1
          ELSE 0
    END
    editor_version,
    CASE WHEN inbox_type='private' THEN 0
          WHEN inbox_type='open' THEN 1
          ELSE 0
    END
    inbox_type,
    users.created_at,
    display_announcements,
    display_sponsors,
    feed_mark_canonical,
    feed_referential_link,
    feed_url,
    experience_level,
    inbox_guidelines,
    users.updated_at,
    data ->> 'brand_color1' AS brand_color1,
    data ->> 'brand_color2' AS brand_color2,
    COALESCE((data ->> 'display_email_on_profile')::boolean, false) as display_email_on_profile
  FROM users
  JOIN profiles
    ON profiles.user_id = users.id
)
INSERT INTO users_settings (user_id, config_font, config_navbar, config_theme, editor_version, inbox_type, created_at, display_announcements, display_sponsors, feed_mark_canonical, feed_referential_link, feed_url, experience_level, inbox_guidelines, updated_at, brand_color1, brand_color2, display_email_on_profile)
  SELECT * FROM settings_data
  ON CONFLICT (user_id) DO UPDATE
    SET config_font = EXCLUDED.config_font,
        config_navbar = EXCLUDED.config_navbar,
        config_theme = EXCLUDED.config_theme,
        editor_version = EXCLUDED.editor_version,
        inbox_type = EXCLUDED.inbox_type,
        display_announcements = EXCLUDED.display_announcements,
        display_sponsors = EXCLUDED.display_sponsors,
        feed_mark_canonical = EXCLUDED.feed_mark_canonical,
        feed_referential_link = EXCLUDED.feed_referential_link,
        feed_url = EXCLUDED.feed_url,
        experience_level = EXCLUDED.experience_level,
        inbox_guidelines = EXCLUDED.inbox_guidelines,
        updated_at = EXCLUDED.updated_at,
        brand_color1 = EXCLUDED.brand_color1,
        brand_color2 = EXCLUDED.brand_color2,
        display_email_on_profile = EXCLUDED.display_email_on_profile;
COMMIT;

-- WHERE [NOT] EXISTS (SELECT user_id FROM users_settings)
ON CONFLICT (user_id) DO UPDATE
    SET config_font = EXCLUDED.config_font,
        config_navbar = EXCLUDED.config_navbar,
        config_theme = EXCLUDED.config_theme,
        editor_version = EXCLUDED.editor_version,
        inbox_type = EXCLUDED.inbox_type,
        display_announcements = EXCLUDED.display_announcements,
        display_sponsors = EXCLUDED.display_sponsors,
        feed_mark_canonical = EXCLUDED.feed_mark_canonical,
        feed_referential_link = EXCLUDED.feed_referential_link,
        feed_url = EXCLUDED.feed_url,
        experience_level = EXCLUDED.experience_level,
        inbox_guidelines = EXCLUDED.inbox_guidelines,
        updated_at = EXCLUDED.updated_at,
        brand_color1 = EXCLUDED.brand_color1,
        brand_color2 = EXCLUDED.brand_color2;