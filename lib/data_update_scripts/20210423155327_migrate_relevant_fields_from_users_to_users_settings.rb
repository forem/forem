module DataUpdateScripts
  class MigrateRelevantFieldsFromUsersToUsersSettings
    def run
      # rubocop:disable Metrics/BlockLength(RuboCop)
      ActiveRecord::Base.transaction do
        ActiveRecord::Base.connection.execute(
          <<~SQL.squish,
            WITH settings_data AS (
              SELECT
                data ->> 'brand_color1' AS brand_color1,
                data ->> 'brand_color2' AS brand_color2,
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
                COALESCE(display_announcements, true),
                COALESCE((data ->> 'display_email_on_profile')::boolean, false) as display_email_on_profile,
                COALESCE(display_sponsors, true),
                CASE WHEN editor_version='v2' THEN 0
                      WHEN editor_version='v1' THEN 1
                      ELSE 0
                END
                editor_version,
                experience_level,
                COALESCE(feed_mark_canonical, false),
                COALESCE(feed_referential_link, true),
                feed_url,
                inbox_guidelines,
                CASE WHEN inbox_type='private' THEN 0
                      WHEN inbox_type='open' THEN 1
                      ELSE 0
                END
                inbox_type,
                COALESCE(permit_adjacent_sponsors, true),
                users.id AS user_id,
                NOW(),
                NOW()
              FROM users
              JOIN profiles
                ON profiles.user_id = users.id
            )
            INSERT INTO users_settings (brand_color1, brand_color2, config_font, config_navbar, config_theme, display_announcements, display_email_on_profile, display_sponsors, editor_version, experience_level, feed_mark_canonical, feed_referential_link, feed_url, inbox_guidelines, inbox_type, permit_adjacent_sponsors, user_id, created_at, updated_at)
              SELECT * FROM settings_data
              ON CONFLICT (user_id) DO UPDATE
                SET brand_color1 = EXCLUDED.brand_color1,
                    brand_color2 = EXCLUDED.brand_color2,
                    config_font = EXCLUDED.config_font,
                    config_navbar = EXCLUDED.config_navbar,
                    config_theme = EXCLUDED.config_theme,
                    display_announcements = EXCLUDED.display_announcements,
                    display_email_on_profile = EXCLUDED.display_email_on_profile,
                    display_sponsors = EXCLUDED.display_sponsors,
                    editor_version = EXCLUDED.editor_version,
                    experience_level = EXCLUDED.experience_level,
                    feed_mark_canonical = EXCLUDED.feed_mark_canonical,
                    feed_referential_link = EXCLUDED.feed_referential_link,
                    feed_url = EXCLUDED.feed_url,
                    inbox_guidelines = EXCLUDED.inbox_guidelines,
                    inbox_type = EXCLUDED.inbox_type,
                    permit_adjacent_sponsors = EXCLUDED.permit_adjacent_sponsors,
                    updated_at = NOW();
          SQL
        )
      end
      # rubocop:enable Metrics/BlockLength(RuboCop)
    end
  end
end
