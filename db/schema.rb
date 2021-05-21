# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_05_11_073505) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_trgm"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "unaccent"

  create_table "ahoy_events", force: :cascade do |t|
    t.string "name"
    t.jsonb "properties"
    t.datetime "time"
    t.bigint "user_id"
    t.bigint "visit_id"
    t.index ["name", "time"], name: "index_ahoy_events_on_name_and_time"
    t.index ["properties"], name: "index_ahoy_events_on_properties", opclass: :jsonb_path_ops, using: :gin
    t.index ["user_id"], name: "index_ahoy_events_on_user_id"
    t.index ["visit_id"], name: "index_ahoy_events_on_visit_id"
  end

  create_table "ahoy_messages", force: :cascade do |t|
    t.datetime "clicked_at"
    t.text "content"
    t.bigint "feedback_message_id"
    t.string "mailer"
    t.datetime "sent_at"
    t.text "subject"
    t.text "to"
    t.string "token"
    t.bigint "user_id"
    t.string "user_type"
    t.string "utm_campaign"
    t.string "utm_content"
    t.string "utm_medium"
    t.string "utm_source"
    t.string "utm_term"
    t.index ["feedback_message_id"], name: "index_ahoy_messages_on_feedback_message_id"
    t.index ["to"], name: "index_ahoy_messages_on_to"
    t.index ["token"], name: "index_ahoy_messages_on_token"
    t.index ["user_id", "mailer"], name: "index_ahoy_messages_on_user_id_and_mailer"
    t.index ["user_id", "user_type"], name: "index_ahoy_messages_on_user_id_and_user_type"
  end

  create_table "ahoy_visits", force: :cascade do |t|
    t.datetime "started_at"
    t.bigint "user_id"
    t.string "visit_token"
    t.string "visitor_token"
    t.index ["user_id"], name: "index_ahoy_visits_on_user_id"
    t.index ["visit_token"], name: "index_ahoy_visits_on_visit_token", unique: true
  end

  create_table "announcements", force: :cascade do |t|
    t.string "banner_style"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "api_secrets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.string "secret"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["secret"], name: "index_api_secrets_on_secret", unique: true
    t.index ["user_id"], name: "index_api_secrets_on_user_id"
  end

  create_table "articles", force: :cascade do |t|
    t.boolean "any_comments_hidden", default: false
    t.boolean "approved", default: false
    t.boolean "archived", default: false
    t.text "body_html"
    t.text "body_markdown"
    t.jsonb "boost_states", default: {}, null: false
    t.text "cached_organization"
    t.string "cached_tag_list"
    t.text "cached_user"
    t.string "cached_user_name"
    t.string "cached_user_username"
    t.string "canonical_url"
    t.bigint "co_author_ids", default: [], array: true
    t.bigint "collection_id"
    t.integer "comment_score", default: 0
    t.string "comment_template"
    t.integer "comments_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "crossposted_at"
    t.string "description"
    t.datetime "edited_at"
    t.boolean "email_digest_eligible", default: true
    t.float "experience_level_rating", default: 5.0
    t.float "experience_level_rating_distribution", default: 5.0
    t.boolean "featured", default: false
    t.integer "featured_number"
    t.string "feed_source_url"
    t.integer "hotness_score", default: 0
    t.datetime "last_comment_at", default: "2017-01-01 05:00:00"
    t.datetime "last_experience_level_rating_at"
    t.string "main_image"
    t.string "main_image_background_hex_color", default: "#dddddd"
    t.integer "nth_published_by_author", default: 0
    t.integer "organic_page_views_count", default: 0
    t.integer "organic_page_views_past_month_count", default: 0
    t.integer "organic_page_views_past_week_count", default: 0
    t.bigint "organization_id"
    t.datetime "originally_published_at"
    t.integer "page_views_count", default: 0
    t.string "password"
    t.string "path"
    t.integer "positive_reactions_count", default: 0, null: false
    t.integer "previous_positive_reactions_count", default: 0
    t.integer "previous_public_reactions_count", default: 0, null: false
    t.text "processed_html"
    t.integer "public_reactions_count", default: 0, null: false
    t.boolean "published", default: false
    t.datetime "published_at"
    t.boolean "published_from_feed", default: false
    t.integer "rating_votes_count", default: 0, null: false
    t.integer "reactions_count", default: 0, null: false
    t.tsvector "reading_list_document"
    t.integer "reading_time", default: 0
    t.boolean "receive_notifications", default: true
    t.integer "score", default: 0
    t.string "search_optimized_description_replacement"
    t.string "search_optimized_title_preamble"
    t.boolean "show_comments", default: true
    t.text "slug"
    t.string "social_image"
    t.integer "spaminess_rating", default: 0
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.integer "user_subscriptions_count", default: 0, null: false
    t.string "video"
    t.string "video_closed_caption_track_url"
    t.string "video_code"
    t.float "video_duration_in_seconds", default: 0.0
    t.string "video_source_url"
    t.string "video_state"
    t.string "video_thumbnail_url"
    t.index "user_id, title, digest(body_markdown, 'sha512'::text)", name: "index_articles_on_user_id_and_title_and_digest_body_markdown", unique: true
    t.index ["boost_states"], name: "index_articles_on_boost_states", using: :gin
    t.index ["cached_tag_list"], name: "index_articles_on_cached_tag_list", opclass: :gin_trgm_ops, using: :gin
    t.index ["canonical_url"], name: "index_articles_on_canonical_url", unique: true
    t.index ["collection_id"], name: "index_articles_on_collection_id"
    t.index ["comment_score"], name: "index_articles_on_comment_score"
    t.index ["comments_count"], name: "index_articles_on_comments_count"
    t.index ["featured_number"], name: "index_articles_on_featured_number"
    t.index ["feed_source_url"], name: "index_articles_on_feed_source_url", unique: true
    t.index ["hotness_score", "comments_count"], name: "index_articles_on_hotness_score_and_comments_count"
    t.index ["hotness_score"], name: "index_articles_on_hotness_score"
    t.index ["path"], name: "index_articles_on_path"
    t.index ["public_reactions_count"], name: "index_articles_on_public_reactions_count", order: :desc
    t.index ["published"], name: "index_articles_on_published"
    t.index ["published_at"], name: "index_articles_on_published_at"
    t.index ["reading_list_document"], name: "index_articles_on_reading_list_document", using: :gin
    t.index ["slug", "user_id"], name: "index_articles_on_slug_and_user_id", unique: true
    t.index ["user_id"], name: "index_articles_on_user_id"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.jsonb "data", default: {}, null: false
    t.string "roles", array: true
    t.string "slug"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["data"], name: "index_audit_logs_on_data", using: :gin
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "badge_achievements", force: :cascade do |t|
    t.bigint "badge_id", null: false
    t.datetime "created_at", null: false
    t.bigint "rewarder_id"
    t.text "rewarding_context_message"
    t.text "rewarding_context_message_markdown"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["badge_id", "user_id"], name: "index_badge_achievements_on_badge_id_and_user_id", unique: true
    t.index ["user_id", "badge_id"], name: "index_badge_achievements_on_user_id_and_badge_id"
  end

  create_table "badges", force: :cascade do |t|
    t.string "badge_image"
    t.datetime "created_at", null: false
    t.integer "credits_awarded", default: 0, null: false
    t.string "description", null: false
    t.string "slug", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_badges_on_slug", unique: true
    t.index ["title"], name: "index_badges_on_title", unique: true
  end

  create_table "banished_users", force: :cascade do |t|
    t.bigint "banished_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["banished_by_id"], name: "index_banished_users_on_banished_by_id"
    t.index ["username"], name: "index_banished_users_on_username", unique: true
  end

  create_table "blazer_audits", force: :cascade do |t|
    t.datetime "created_at"
    t.string "data_source"
    t.bigint "query_id"
    t.text "statement"
    t.bigint "user_id"
    t.index ["query_id"], name: "index_blazer_audits_on_query_id"
    t.index ["user_id"], name: "index_blazer_audits_on_user_id"
  end

  create_table "blazer_checks", force: :cascade do |t|
    t.string "check_type"
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.text "emails"
    t.datetime "last_run_at"
    t.text "message"
    t.bigint "query_id"
    t.string "schedule"
    t.text "slack_channels"
    t.string "state"
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_checks_on_creator_id"
    t.index ["query_id"], name: "index_blazer_checks_on_query_id"
  end

  create_table "blazer_dashboard_queries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "dashboard_id"
    t.integer "position"
    t.bigint "query_id"
    t.datetime "updated_at", null: false
    t.index ["dashboard_id"], name: "index_blazer_dashboard_queries_on_dashboard_id"
    t.index ["query_id"], name: "index_blazer_dashboard_queries_on_query_id"
  end

  create_table "blazer_dashboards", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.text "name"
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_dashboards_on_creator_id"
  end

  create_table "blazer_queries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.string "data_source"
    t.text "description"
    t.string "name"
    t.text "statement"
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_queries_on_creator_id"
  end

  create_table "broadcasts", force: :cascade do |t|
    t.boolean "active", default: false
    t.datetime "active_status_updated_at"
    t.string "banner_style"
    t.text "body_markdown"
    t.bigint "broadcastable_id"
    t.string "broadcastable_type"
    t.datetime "created_at"
    t.text "processed_html"
    t.string "title"
    t.string "type_of"
    t.datetime "updated_at"
    t.index ["broadcastable_type", "broadcastable_id"], name: "index_broadcasts_on_broadcastable_type_and_broadcastable_id", unique: true
    t.index ["title", "type_of"], name: "index_broadcasts_on_title_and_type_of", unique: true
  end

  create_table "chat_channel_memberships", force: :cascade do |t|
    t.bigint "chat_channel_id", null: false
    t.datetime "created_at", null: false
    t.boolean "has_unopened_messages", default: false
    t.datetime "last_opened_at", default: "2017-01-01 05:00:00"
    t.string "role", default: "member"
    t.boolean "show_global_badge_notification", default: true
    t.string "status", default: "active"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["chat_channel_id", "user_id"], name: "index_chat_channel_memberships_on_chat_channel_id_and_user_id", unique: true
    t.index ["user_id", "chat_channel_id"], name: "index_chat_channel_memberships_on_user_id_and_chat_channel_id"
  end

  create_table "chat_channels", force: :cascade do |t|
    t.string "channel_name"
    t.string "channel_type", null: false
    t.datetime "created_at", null: false
    t.string "description"
    t.boolean "discoverable", default: false
    t.datetime "last_message_at", default: "2017-01-01 05:00:00"
    t.string "slug"
    t.string "status", default: "active"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_chat_channels_on_slug", unique: true
  end

  create_table "classified_listing_categories", force: :cascade do |t|
    t.integer "cost", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "rules", null: false
    t.string "slug", null: false
    t.string "social_preview_color"
    t.string "social_preview_description"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_classified_listing_categories_on_name", unique: true
    t.index ["slug"], name: "index_classified_listing_categories_on_slug", unique: true
  end

  create_table "classified_listings", force: :cascade do |t|
    t.text "body_markdown"
    t.datetime "bumped_at"
    t.string "cached_tag_list"
    t.bigint "classified_listing_category_id"
    t.boolean "contact_via_connect", default: false
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.string "location"
    t.bigint "organization_id"
    t.datetime "originally_published_at"
    t.text "processed_html"
    t.boolean "published"
    t.string "slug"
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index "(((((to_tsvector('simple'::regconfig, COALESCE(body_markdown, ''::text)) || to_tsvector('simple'::regconfig, COALESCE((cached_tag_list)::text, ''::text))) || to_tsvector('simple'::regconfig, COALESCE((location)::text, ''::text))) || to_tsvector('simple'::regconfig, COALESCE((slug)::text, ''::text))) || to_tsvector('simple'::regconfig, COALESCE((title)::text, ''::text))))", name: "index_classified_listings_on_search_fields_as_tsvector", using: :gin
    t.index ["classified_listing_category_id"], name: "index_classified_listings_on_classified_listing_category_id"
    t.index ["organization_id"], name: "index_classified_listings_on_organization_id"
    t.index ["published"], name: "index_classified_listings_on_published"
    t.index ["user_id"], name: "index_classified_listings_on_user_id"
  end

  create_table "collections", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.string "main_image"
    t.bigint "organization_id"
    t.boolean "published", default: false
    t.string "slug"
    t.string "social_image"
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["organization_id"], name: "index_collections_on_organization_id"
    t.index ["slug", "user_id"], name: "index_collections_on_slug_and_user_id", unique: true
    t.index ["user_id"], name: "index_collections_on_user_id"
  end

  create_table "comments", force: :cascade do |t|
    t.string "ancestry"
    t.text "body_html"
    t.text "body_markdown"
    t.bigint "commentable_id"
    t.string "commentable_type"
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false
    t.boolean "edited", default: false
    t.datetime "edited_at"
    t.boolean "hidden_by_commentable_user", default: false
    t.string "id_code"
    t.integer "markdown_character_count"
    t.integer "positive_reactions_count", default: 0, null: false
    t.text "processed_html"
    t.integer "public_reactions_count", default: 0, null: false
    t.integer "reactions_count", default: 0, null: false
    t.boolean "receive_notifications", default: true
    t.integer "score", default: 0
    t.integer "spaminess_rating", default: 0
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index "digest(body_markdown, 'sha512'::text), user_id, ancestry, commentable_id, commentable_type", name: "index_comments_on_body_markdown_user_ancestry_commentable", unique: true
    t.index "to_tsvector('simple'::regconfig, COALESCE(body_markdown, ''::text))", name: "index_comments_on_body_markdown_as_tsvector", using: :gin
    t.index ["ancestry"], name: "index_comments_on_ancestry"
    t.index ["ancestry"], name: "index_comments_on_ancestry_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["commentable_id", "commentable_type"], name: "index_comments_on_commentable_id_and_commentable_type"
    t.index ["created_at"], name: "index_comments_on_created_at"
    t.index ["deleted"], name: "index_comments_on_deleted", where: "(deleted = false)"
    t.index ["hidden_by_commentable_user"], name: "index_comments_on_hidden_by_commentable_user", where: "(hidden_by_commentable_user = false)"
    t.index ["score"], name: "index_comments_on_score"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "consumer_apps", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "app_bundle", null: false
    t.string "auth_key"
    t.datetime "created_at", precision: 6, null: false
    t.string "last_error"
    t.string "platform", null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["app_bundle", "platform"], name: "index_consumer_apps_on_app_bundle_and_platform", unique: true
  end

  create_table "credits", force: :cascade do |t|
    t.float "cost", default: 0.0
    t.datetime "created_at", null: false
    t.bigint "organization_id"
    t.bigint "purchase_id"
    t.string "purchase_type"
    t.boolean "spent", default: false
    t.datetime "spent_at"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["purchase_id", "purchase_type"], name: "index_credits_on_purchase_id_and_purchase_type"
    t.index ["spent"], name: "index_credits_on_spent"
  end

  create_table "custom_profile_fields", force: :cascade do |t|
    t.string "attribute_name", null: false
    t.datetime "created_at", precision: 6, null: false
    t.string "description"
    t.citext "label", null: false
    t.bigint "profile_id", null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["label", "profile_id"], name: "index_custom_profile_fields_on_label_and_profile_id", unique: true
    t.index ["profile_id"], name: "index_custom_profile_fields_on_profile_id"
  end

  create_table "data_update_scripts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.string "file_name"
    t.datetime "finished_at"
    t.datetime "run_at"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["file_name"], name: "index_data_update_scripts_on_file_name", unique: true
  end

  create_table "devices", force: :cascade do |t|
    t.string "app_bundle"
    t.bigint "consumer_app_id"
    t.datetime "created_at", precision: 6, null: false
    t.string "platform", null: false
    t.string "token", null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "user_id", null: false
    t.index ["consumer_app_id"], name: "index_devices_on_consumer_app_id"
    t.index ["user_id", "token", "platform", "consumer_app_id"], name: "index_devices_on_user_id_and_token_and_platform_and_app", unique: true
  end

  create_table "display_ad_events", force: :cascade do |t|
    t.string "category"
    t.string "context_type"
    t.datetime "created_at", null: false
    t.bigint "display_ad_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["display_ad_id"], name: "index_display_ad_events_on_display_ad_id"
    t.index ["user_id"], name: "index_display_ad_events_on_user_id"
  end

  create_table "display_ads", force: :cascade do |t|
    t.boolean "approved", default: false
    t.text "body_markdown"
    t.integer "clicks_count", default: 0
    t.datetime "created_at", null: false
    t.integer "impressions_count", default: 0
    t.bigint "organization_id"
    t.string "placement_area"
    t.text "processed_html"
    t.boolean "published", default: false
    t.float "success_rate", default: 0.0
    t.datetime "updated_at", null: false
  end

  create_table "email_authorizations", force: :cascade do |t|
    t.string "confirmation_token"
    t.datetime "created_at", null: false
    t.jsonb "json_data", default: {}, null: false
    t.string "type_of", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.datetime "verified_at"
    t.index ["user_id"], name: "index_email_authorizations_on_user_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "category"
    t.string "cover_image"
    t.datetime "created_at", null: false
    t.text "description_html"
    t.text "description_markdown"
    t.datetime "ends_at"
    t.string "host_name"
    t.boolean "live_now", default: false
    t.string "location_name"
    t.string "location_url"
    t.string "profile_image"
    t.boolean "published"
    t.string "slug"
    t.datetime "starts_at"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "feedback_messages", force: :cascade do |t|
    t.bigint "affected_id"
    t.string "category"
    t.datetime "created_at"
    t.string "feedback_type"
    t.text "message"
    t.bigint "offender_id"
    t.string "reported_url"
    t.bigint "reporter_id"
    t.string "status", default: "Open"
    t.datetime "updated_at"
    t.index ["affected_id"], name: "index_feedback_messages_on_affected_id"
    t.index ["offender_id"], name: "index_feedback_messages_on_offender_id"
    t.index ["reporter_id"], name: "index_feedback_messages_on_reporter_id"
    t.index ["status"], name: "index_feedback_messages_on_status"
  end

  create_table "field_test_events", force: :cascade do |t|
    t.datetime "created_at"
    t.bigint "field_test_membership_id"
    t.string "name"
    t.index ["field_test_membership_id"], name: "index_field_test_events_on_field_test_membership_id"
  end

  create_table "field_test_memberships", force: :cascade do |t|
    t.boolean "converted", default: false
    t.datetime "created_at"
    t.string "experiment"
    t.string "participant_id"
    t.string "participant_type"
    t.string "variant"
    t.index ["experiment", "created_at"], name: "index_field_test_memberships_on_experiment_and_created_at"
    t.index ["participant_type", "participant_id", "experiment"], name: "index_field_test_memberships_on_participant", unique: true
  end

  create_table "flipper_features", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "feature_key", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.string "value"
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "follows", force: :cascade do |t|
    t.boolean "blocked", default: false, null: false
    t.datetime "created_at"
    t.float "explicit_points", default: 1.0
    t.bigint "followable_id", null: false
    t.string "followable_type", null: false
    t.bigint "follower_id", null: false
    t.string "follower_type", null: false
    t.float "implicit_points", default: 0.0
    t.float "points", default: 1.0
    t.string "subscription_status", default: "all_articles", null: false
    t.datetime "updated_at"
    t.index ["created_at"], name: "index_follows_on_created_at"
    t.index ["followable_id", "followable_type", "follower_id", "follower_type"], name: "index_follows_on_followable_and_follower", unique: true
    t.index ["followable_id", "followable_type"], name: "fk_followables"
    t.index ["follower_id", "follower_type"], name: "fk_follows"
  end

  create_table "github_issues", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.string "issue_serialized", default: "--- {}\n"
    t.string "processed_html"
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["url"], name: "index_github_issues_on_url", unique: true
  end

  create_table "github_repos", force: :cascade do |t|
    t.string "additional_note"
    t.integer "bytes_size"
    t.datetime "created_at", null: false
    t.string "description"
    t.boolean "featured", default: false
    t.boolean "fork", default: false
    t.bigint "github_id_code"
    t.text "info_hash", default: "--- {}\n"
    t.string "language"
    t.string "name"
    t.integer "priority", default: 0
    t.integer "stargazers_count"
    t.datetime "updated_at", null: false
    t.string "url"
    t.bigint "user_id"
    t.integer "watchers_count"
    t.index ["github_id_code"], name: "index_github_repos_on_github_id_code", unique: true
    t.index ["url"], name: "index_github_repos_on_url", unique: true
  end

  create_table "html_variant_successes", force: :cascade do |t|
    t.bigint "article_id"
    t.datetime "created_at", null: false
    t.bigint "html_variant_id"
    t.datetime "updated_at", null: false
    t.index ["html_variant_id", "article_id"], name: "index_html_variant_successes_on_html_variant_id_and_article_id"
  end

  create_table "html_variant_trials", force: :cascade do |t|
    t.bigint "article_id"
    t.datetime "created_at", null: false
    t.bigint "html_variant_id"
    t.datetime "updated_at", null: false
    t.index ["html_variant_id", "article_id"], name: "index_html_variant_trials_on_html_variant_id_and_article_id"
  end

  create_table "html_variants", force: :cascade do |t|
    t.boolean "approved", default: false
    t.datetime "created_at", null: false
    t.string "group"
    t.text "html"
    t.string "name"
    t.boolean "published", default: false
    t.float "success_rate", default: 0.0
    t.string "target_tag"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["name"], name: "index_html_variants_on_name", unique: true
  end

  create_table "identities", force: :cascade do |t|
    t.text "auth_data_dump"
    t.datetime "created_at", null: false
    t.string "provider"
    t.string "secret"
    t.string "token"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["provider", "uid"], name: "index_identities_on_provider_and_uid", unique: true
    t.index ["provider", "user_id"], name: "index_identities_on_provider_and_user_id", unique: true
  end

  create_table "mentions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "mentionable_id"
    t.string "mentionable_type"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id", "mentionable_id", "mentionable_type"], name: "index_mentions_on_user_id_and_mentionable_id_mentionable_type", unique: true
  end

  create_table "messages", force: :cascade do |t|
    t.string "chat_action"
    t.bigint "chat_channel_id", null: false
    t.datetime "created_at", null: false
    t.datetime "edited_at"
    t.string "message_html", null: false
    t.string "message_markdown", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["chat_channel_id"], name: "index_messages_on_chat_channel_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "navigation_links", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.boolean "display_only_when_signed_in", default: false
    t.string "icon", null: false
    t.string "name", null: false
    t.integer "position"
    t.datetime "updated_at", precision: 6, null: false
    t.string "url", null: false
    t.index ["url", "name"], name: "index_navigation_links_on_url_and_name", unique: true
  end

  create_table "notes", force: :cascade do |t|
    t.bigint "author_id"
    t.text "content"
    t.datetime "created_at", null: false
    t.bigint "noteable_id"
    t.string "noteable_type"
    t.string "reason"
    t.datetime "updated_at", null: false
  end

  create_table "notification_subscriptions", force: :cascade do |t|
    t.text "config", default: "all_comments", null: false
    t.datetime "created_at", null: false
    t.bigint "notifiable_id", null: false
    t.string "notifiable_type", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["notifiable_id", "notifiable_type", "config"], name: "index_notification_subscriptions_on_notifiable_and_config"
    t.index ["user_id", "notifiable_type", "notifiable_id"], name: "idx_notification_subs_on_user_id_notifiable_type_notifiable_id", unique: true
  end

  create_table "notifications", force: :cascade do |t|
    t.string "action"
    t.datetime "created_at", null: false
    t.jsonb "json_data"
    t.bigint "notifiable_id"
    t.string "notifiable_type"
    t.datetime "notified_at"
    t.bigint "organization_id"
    t.boolean "read", default: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["created_at"], name: "index_notifications_on_created_at"
    t.index ["notifiable_id", "notifiable_type", "action"], name: "index_notifications_on_notifiable_id_notifiable_type_and_action"
    t.index ["notifiable_type"], name: "index_notifications_on_notifiable_type"
    t.index ["notified_at"], name: "index_notifications_on_notified_at"
    t.index ["organization_id", "notifiable_id", "notifiable_type", "action"], name: "index_notifications_on_org_notifiable_and_action_not_null", unique: true, where: "(action IS NOT NULL)"
    t.index ["organization_id", "notifiable_id", "notifiable_type"], name: "index_notifications_on_org_notifiable_action_is_null", unique: true, where: "(action IS NULL)"
    t.index ["user_id", "notifiable_id", "notifiable_type", "action"], name: "index_notifications_on_user_notifiable_and_action_not_null", unique: true, where: "(action IS NOT NULL)"
    t.index ["user_id", "notifiable_id", "notifiable_type"], name: "index_notifications_on_user_notifiable_action_is_null", unique: true, where: "(action IS NULL)"
    t.index ["user_id", "organization_id", "notifiable_id", "notifiable_type", "action"], name: "index_notifications_user_id_organization_id_notifiable_action", unique: true
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.bigint "application_id", null: false
    t.datetime "created_at", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.bigint "resource_owner_id", null: false
    t.datetime "revoked_at"
    t.string "scopes"
    t.string "token", null: false
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["resource_owner_id"], name: "index_oauth_access_grants_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.bigint "application_id", null: false
    t.datetime "created_at", null: false
    t.integer "expires_in"
    t.string "previous_refresh_token", default: "", null: false
    t.string "refresh_token"
    t.bigint "resource_owner_id"
    t.datetime "revoked_at"
    t.string "scopes"
    t.string "token", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.string "secret", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "organization_memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "organization_id", null: false
    t.string "type_of_user", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "user_title"
    t.index ["user_id", "organization_id"], name: "index_organization_memberships_on_user_id_and_organization_id", unique: true
  end

  create_table "organizations", force: :cascade do |t|
    t.integer "articles_count", default: 0, null: false
    t.string "bg_color_hex"
    t.string "company_size"
    t.datetime "created_at", null: false
    t.integer "credits_count", default: 0, null: false
    t.text "cta_body_markdown"
    t.string "cta_button_text"
    t.string "cta_button_url"
    t.text "cta_processed_html"
    t.string "dark_nav_image"
    t.string "email"
    t.string "github_username"
    t.datetime "last_article_at", default: "2017-01-01 05:00:00"
    t.datetime "latest_article_updated_at"
    t.string "location"
    t.string "name"
    t.string "nav_image"
    t.string "old_old_slug"
    t.string "old_slug"
    t.string "profile_image"
    t.datetime "profile_updated_at", default: "2017-01-01 05:00:00"
    t.text "proof"
    t.string "secret"
    t.string "slug"
    t.integer "spent_credits_count", default: 0, null: false
    t.string "story"
    t.text "summary"
    t.string "tag_line"
    t.string "tech_stack"
    t.string "text_color_hex"
    t.string "twitter_username"
    t.integer "unspent_credits_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["secret"], name: "index_organizations_on_secret", unique: true
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
  end

  create_table "page_views", force: :cascade do |t|
    t.bigint "article_id"
    t.integer "counts_for_number_of_views", default: 1
    t.datetime "created_at", null: false
    t.string "domain"
    t.string "path"
    t.string "referrer"
    t.integer "time_tracked_in_seconds", default: 15
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id"
    t.index ["article_id"], name: "index_page_views_on_article_id"
    t.index ["created_at"], name: "index_page_views_on_created_at"
    t.index ["user_id"], name: "index_page_views_on_user_id"
  end

  create_table "pages", force: :cascade do |t|
    t.text "body_html"
    t.jsonb "body_json"
    t.text "body_markdown"
    t.datetime "created_at", null: false
    t.string "description"
    t.boolean "is_top_level_path", default: false
    t.boolean "landing_page", default: false, null: false
    t.text "processed_html"
    t.string "slug"
    t.string "social_image"
    t.string "template"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_pages_on_slug", unique: true
  end

  create_table "podcast_episode_appearances", force: :cascade do |t|
    t.boolean "approved", default: false, null: false
    t.datetime "created_at", precision: 6, null: false
    t.boolean "featured_on_user_profile", default: false, null: false
    t.bigint "podcast_episode_id", null: false
    t.string "role", default: "guest", null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "user_id", null: false
    t.index ["podcast_episode_id", "user_id"], name: "index_pod_episode_appearances_on_podcast_episode_id_and_user_id", unique: true
  end

  create_table "podcast_episodes", force: :cascade do |t|
    t.boolean "any_comments_hidden", default: false
    t.text "body"
    t.integer "comments_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "duration_in_seconds"
    t.string "guid", null: false
    t.boolean "https", default: true
    t.string "image"
    t.string "itunes_url"
    t.string "media_url", null: false
    t.bigint "podcast_id"
    t.text "processed_html"
    t.datetime "published_at"
    t.text "quote"
    t.boolean "reachable", default: true
    t.integer "reactions_count", default: 0, null: false
    t.string "slug", null: false
    t.string "social_image"
    t.string "status_notice"
    t.string "subtitle"
    t.text "summary"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.string "website_url"
    t.index "(((to_tsvector('simple'::regconfig, COALESCE(body, ''::text)) || to_tsvector('simple'::regconfig, COALESCE((subtitle)::text, ''::text))) || to_tsvector('simple'::regconfig, COALESCE((title)::text, ''::text))))", name: "index_podcast_episodes_on_search_fields_as_tsvector", using: :gin
    t.index ["guid"], name: "index_podcast_episodes_on_guid", unique: true
    t.index ["media_url"], name: "index_podcast_episodes_on_media_url", unique: true
    t.index ["podcast_id"], name: "index_podcast_episodes_on_podcast_id"
    t.index ["title"], name: "index_podcast_episodes_on_title"
    t.index ["website_url"], name: "index_podcast_episodes_on_website_url"
  end

  create_table "podcast_ownerships", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.bigint "podcast_id", null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "user_id", null: false
    t.index ["podcast_id", "user_id"], name: "index_podcast_ownerships_on_podcast_id_and_user_id", unique: true
  end

  create_table "podcasts", force: :cascade do |t|
    t.string "android_url"
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.text "description"
    t.string "feed_url", null: false
    t.string "image", null: false
    t.string "itunes_url"
    t.string "main_color_hex", null: false
    t.string "overcast_url"
    t.string "pattern_image"
    t.boolean "published", default: false
    t.boolean "reachable", default: true
    t.string "slug", null: false
    t.string "soundcloud_url"
    t.text "status_notice", default: ""
    t.string "title", null: false
    t.string "twitter_username"
    t.boolean "unique_website_url?", default: true
    t.datetime "updated_at", null: false
    t.string "website_url"
    t.index ["creator_id"], name: "index_podcasts_on_creator_id"
    t.index ["feed_url"], name: "index_podcasts_on_feed_url", unique: true
    t.index ["published"], name: "index_podcasts_on_published", where: "(published = true)"
    t.index ["reachable"], name: "index_podcasts_on_reachable", where: "(reachable = true)"
    t.index ["slug"], name: "index_podcasts_on_slug", unique: true
  end

  create_table "poll_options", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "markdown"
    t.bigint "poll_id"
    t.integer "poll_votes_count", default: 0, null: false
    t.string "processed_html"
    t.datetime "updated_at", null: false
  end

  create_table "poll_skips", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "poll_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["poll_id", "user_id"], name: "index_poll_skips_on_poll_and_user", unique: true
  end

  create_table "poll_votes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "poll_id", null: false
    t.bigint "poll_option_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["poll_id", "user_id"], name: "index_poll_votes_on_poll_id_and_user_id", unique: true
    t.index ["poll_option_id", "user_id"], name: "index_poll_votes_on_poll_option_and_user", unique: true
  end

  create_table "polls", force: :cascade do |t|
    t.bigint "article_id"
    t.datetime "created_at", null: false
    t.integer "poll_options_count", default: 0, null: false
    t.integer "poll_skips_count", default: 0, null: false
    t.integer "poll_votes_count", default: 0, null: false
    t.string "prompt_html"
    t.string "prompt_markdown"
    t.datetime "updated_at", null: false
  end

  create_table "profile_field_groups", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.string "description"
    t.string "name", null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["name"], name: "index_profile_field_groups_on_name", unique: true
  end

  create_table "profile_fields", force: :cascade do |t|
    t.string "attribute_name", null: false
    t.datetime "created_at", precision: 6, null: false
    t.string "description"
    t.integer "display_area", default: 1, null: false
    t.integer "input_type", default: 0, null: false
    t.citext "label", null: false
    t.string "placeholder_text"
    t.bigint "profile_field_group_id"
    t.boolean "show_in_onboarding", default: false, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["label"], name: "index_profile_fields_on_label", unique: true
    t.index ["profile_field_group_id"], name: "index_profile_fields_on_profile_field_group_id"
  end

  create_table "profile_pins", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "pinnable_id"
    t.string "pinnable_type"
    t.bigint "profile_id"
    t.string "profile_type"
    t.datetime "updated_at", null: false
    t.index ["pinnable_id", "profile_id", "profile_type", "pinnable_type"], name: "idx_pins_on_pinnable_id_profile_id_profile_type_pinnable_type", unique: true
    t.index ["profile_id"], name: "index_profile_pins_on_profile_id"
  end

  create_table "profiles", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.jsonb "data", default: {}, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_profiles_on_user_id", unique: true
  end

  create_table "rating_votes", force: :cascade do |t|
    t.bigint "article_id"
    t.string "context", default: "explicit"
    t.datetime "created_at", null: false
    t.string "group"
    t.float "rating"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["article_id"], name: "index_rating_votes_on_article_id"
    t.index ["user_id", "article_id", "context"], name: "index_rating_votes_on_user_id_and_article_id_and_context", unique: true
  end

  create_table "reactions", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.float "points", default: 1.0
    t.bigint "reactable_id"
    t.string "reactable_type"
    t.string "status", default: "valid"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["category"], name: "index_reactions_on_category"
    t.index ["created_at"], name: "index_reactions_on_created_at"
    t.index ["points"], name: "index_reactions_on_points"
    t.index ["reactable_id", "reactable_type"], name: "index_reactions_on_reactable_id_and_reactable_type"
    t.index ["reactable_type"], name: "index_reactions_on_reactable_type"
    t.index ["status"], name: "index_reactions_on_status"
    t.index ["user_id", "reactable_id", "reactable_type", "category"], name: "index_reactions_on_user_id_reactable_id_reactable_type_category", unique: true
  end

  create_table "response_templates", force: :cascade do |t|
    t.text "content", null: false
    t.string "content_type", null: false
    t.datetime "created_at", null: false
    t.string "title", null: false
    t.string "type_of", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["content", "user_id", "type_of", "content_type"], name: "idx_response_templates_on_content_user_id_type_of_content_type", unique: true
    t.index ["type_of"], name: "index_response_templates_on_type_of"
    t.index ["user_id", "type_of"], name: "index_response_templates_on_user_id_and_type_of"
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at"
    t.string "name"
    t.bigint "resource_id"
    t.string "resource_type"
    t.datetime "updated_at"
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"
    t.index ["name"], name: "index_roles_on_name"
  end

  create_table "settings_authentications", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "value"
    t.string "var", null: false
    t.index ["var"], name: "index_settings_authentications_on_var", unique: true
  end

  create_table "settings_campaigns", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "value"
    t.string "var", null: false
    t.index ["var"], name: "index_settings_campaigns_on_var", unique: true
  end

  create_table "settings_communities", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "value"
    t.string "var", null: false
    t.index ["var"], name: "index_settings_communities_on_var", unique: true
  end

  create_table "settings_mascots", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "value"
    t.string "var", null: false
    t.index ["var"], name: "index_settings_mascots_on_var", unique: true
  end

  create_table "settings_rate_limits", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "value"
    t.string "var", null: false
    t.index ["var"], name: "index_settings_rate_limits_on_var", unique: true
  end

  create_table "settings_user_experiences", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "value"
    t.string "var", null: false
    t.index ["var"], name: "index_settings_user_experiences_on_var", unique: true
  end

  create_table "site_configs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "value"
    t.string "var", null: false
    t.index ["var"], name: "index_site_configs_on_var", unique: true
  end

  create_table "sponsorships", force: :cascade do |t|
    t.text "blurb_html"
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.integer "featured_number", default: 0, null: false
    t.text "instructions"
    t.datetime "instructions_updated_at"
    t.string "level", null: false
    t.bigint "organization_id"
    t.bigint "sponsorable_id"
    t.string "sponsorable_type"
    t.string "status", default: "none", null: false
    t.string "tagline"
    t.datetime "updated_at", null: false
    t.string "url"
    t.bigint "user_id"
    t.index ["level"], name: "index_sponsorships_on_level"
    t.index ["organization_id"], name: "index_sponsorships_on_organization_id"
    t.index ["sponsorable_id", "sponsorable_type"], name: "index_sponsorships_on_sponsorable_id_and_sponsorable_type"
    t.index ["status"], name: "index_sponsorships_on_status"
    t.index ["user_id"], name: "index_sponsorships_on_user_id"
  end

  create_table "tag_adjustments", force: :cascade do |t|
    t.string "adjustment_type"
    t.bigint "article_id"
    t.datetime "created_at", null: false
    t.string "reason_for_adjustment"
    t.string "status"
    t.bigint "tag_id"
    t.string "tag_name"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["tag_name", "article_id"], name: "index_tag_adjustments_on_tag_name_and_article_id", unique: true
  end

  create_table "taggings", force: :cascade do |t|
    t.string "context", limit: 128
    t.datetime "created_at"
    t.bigint "tag_id"
    t.bigint "taggable_id"
    t.string "taggable_type"
    t.bigint "tagger_id"
    t.string "tagger_type"
    t.index ["context"], name: "index_taggings_on_context"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context"
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy"
    t.index ["taggable_id"], name: "index_taggings_on_taggable_id"
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type"
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type"
    t.index ["tagger_id"], name: "index_taggings_on_tagger_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "alias_for"
    t.bigint "badge_id"
    t.string "bg_color_hex"
    t.string "category", default: "uncategorized", null: false
    t.datetime "created_at"
    t.integer "hotness_score", default: 0
    t.string "keywords_for_search"
    t.bigint "mod_chat_channel_id"
    t.string "name"
    t.string "pretty_name"
    t.string "profile_image"
    t.boolean "requires_approval", default: false
    t.text "rules_html"
    t.text "rules_markdown"
    t.string "short_summary"
    t.string "social_image"
    t.string "social_preview_template", default: "article"
    t.text "submission_template"
    t.boolean "supported", default: false
    t.integer "taggings_count", default: 0
    t.string "text_color_hex"
    t.datetime "updated_at"
    t.text "wiki_body_html"
    t.text "wiki_body_markdown"
    t.index ["name"], name: "index_tags_on_name", unique: true
    t.index ["social_preview_template"], name: "index_tags_on_social_preview_template"
    t.index ["supported"], name: "index_tags_on_supported"
  end

  create_table "tweets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "extended_entities_serialized", default: "--- {}\n"
    t.integer "favorite_count"
    t.text "full_fetched_object_serialized", default: "--- {}\n"
    t.string "hashtags_serialized", default: "--- []\n"
    t.string "in_reply_to_status_id_code"
    t.string "in_reply_to_user_id_code"
    t.string "in_reply_to_username"
    t.boolean "is_quote_status"
    t.datetime "last_fetched_at"
    t.text "media_serialized", default: "--- []\n"
    t.string "mentioned_usernames_serialized", default: "--- []\n"
    t.string "profile_image"
    t.string "quoted_tweet_id_code"
    t.integer "retweet_count"
    t.string "source"
    t.string "text"
    t.datetime "tweeted_at"
    t.string "twitter_id_code"
    t.string "twitter_name"
    t.string "twitter_uid"
    t.integer "twitter_user_followers_count"
    t.integer "twitter_user_following_count"
    t.string "twitter_username"
    t.datetime "updated_at", null: false
    t.text "urls_serialized", default: "--- []\n"
    t.bigint "user_id"
    t.boolean "user_is_verified"
  end

  create_table "user_blocks", force: :cascade do |t|
    t.bigint "blocked_id", null: false
    t.bigint "blocker_id", null: false
    t.string "config", default: "default", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["blocked_id", "blocker_id"], name: "index_user_blocks_on_blocked_id_and_blocker_id", unique: true
  end

  create_table "user_subscriptions", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.string "subscriber_email", null: false
    t.bigint "subscriber_id", null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "user_subscription_sourceable_id"
    t.string "user_subscription_sourceable_type"
    t.index ["author_id"], name: "index_user_subscriptions_on_author_id"
    t.index ["subscriber_email"], name: "index_user_subscriptions_on_subscriber_email"
    t.index ["subscriber_id", "subscriber_email", "user_subscription_sourceable_type", "user_subscription_sourceable_id"], name: "index_subscriber_id_and_email_with_user_subscription_source", unique: true
    t.index ["user_subscription_sourceable_type", "user_subscription_sourceable_id"], name: "index_on_user_subscription_sourcebable_type_and_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "apple_created_at"
    t.string "apple_username"
    t.integer "articles_count", default: 0, null: false
    t.string "available_for"
    t.integer "badge_achievements_count", default: 0, null: false
    t.string "behance_url"
    t.string "bg_color_hex"
    t.bigint "blocked_by_count", default: 0, null: false
    t.bigint "blocking_others_count", default: 0, null: false
    t.boolean "checked_code_of_conduct", default: false
    t.boolean "checked_terms_and_conditions", default: false
    t.integer "comments_count", default: 0, null: false
    t.string "config_font", default: "default"
    t.string "config_navbar", default: "default", null: false
    t.string "config_theme", default: "default"
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.integer "credits_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.inet "current_sign_in_ip"
    t.string "currently_hacking_on"
    t.string "currently_learning"
    t.boolean "display_announcements", default: true
    t.boolean "display_sponsors", default: true
    t.string "dribbble_url"
    t.string "editor_version", default: "v1"
    t.string "education"
    t.string "email"
    t.boolean "email_badge_notifications", default: true
    t.boolean "email_comment_notifications", default: true
    t.boolean "email_community_mod_newsletter", default: false
    t.boolean "email_connect_messages", default: true
    t.boolean "email_digest_periodic", default: false, null: false
    t.boolean "email_follower_notifications", default: true
    t.boolean "email_membership_newsletter", default: false
    t.boolean "email_mention_notifications", default: true
    t.boolean "email_newsletter", default: false
    t.boolean "email_public", default: false
    t.boolean "email_tag_mod_newsletter", default: false
    t.boolean "email_unread_notifications", default: true
    t.string "employer_name"
    t.string "employer_url"
    t.string "employment_title"
    t.string "encrypted_password", default: "", null: false
    t.integer "experience_level"
    t.boolean "export_requested", default: false
    t.datetime "exported_at"
    t.datetime "facebook_created_at"
    t.string "facebook_url"
    t.string "facebook_username"
    t.integer "failed_attempts", default: 0
    t.datetime "feed_fetched_at", default: "2017-01-01 05:00:00"
    t.boolean "feed_mark_canonical", default: false
    t.boolean "feed_referential_link", default: true, null: false
    t.string "feed_url"
    t.integer "following_orgs_count", default: 0, null: false
    t.integer "following_tags_count", default: 0, null: false
    t.integer "following_users_count", default: 0, null: false
    t.datetime "github_created_at"
    t.datetime "github_repos_updated_at", default: "2017-01-01 05:00:00"
    t.string "github_username"
    t.string "gitlab_url"
    t.string "inbox_guidelines"
    t.string "inbox_type", default: "private"
    t.string "instagram_url"
    t.datetime "invitation_accepted_at"
    t.datetime "invitation_created_at"
    t.integer "invitation_limit"
    t.datetime "invitation_sent_at"
    t.string "invitation_token"
    t.integer "invitations_count", default: 0
    t.bigint "invited_by_id"
    t.string "invited_by_type"
    t.datetime "last_article_at", default: "2017-01-01 05:00:00"
    t.datetime "last_comment_at", default: "2017-01-01 05:00:00"
    t.datetime "last_followed_at"
    t.datetime "last_moderation_notification", default: "2017-01-01 05:00:00"
    t.datetime "last_notification_activity"
    t.string "last_onboarding_page"
    t.datetime "last_reacted_at"
    t.datetime "last_sign_in_at"
    t.inet "last_sign_in_ip"
    t.datetime "latest_article_updated_at"
    t.string "linkedin_url"
    t.string "location"
    t.datetime "locked_at"
    t.string "mastodon_url"
    t.string "medium_url"
    t.boolean "mobile_comment_notifications", default: true
    t.boolean "mod_roundrobin_notifications", default: true
    t.integer "monthly_dues", default: 0
    t.string "mostly_work_with"
    t.string "name"
    t.string "old_old_username"
    t.string "old_username"
    t.boolean "onboarding_package_requested", default: false
    t.datetime "organization_info_updated_at"
    t.string "payment_pointer"
    t.boolean "permit_adjacent_sponsors", default: true
    t.string "profile_image"
    t.datetime "profile_updated_at", default: "2017-01-01 05:00:00"
    t.integer "rating_votes_count", default: 0, null: false
    t.boolean "reaction_notifications", default: true
    t.integer "reactions_count", default: 0, null: false
    t.boolean "registered", default: true
    t.datetime "registered_at"
    t.datetime "remember_created_at"
    t.string "remember_token"
    t.float "reputation_modifier", default: 1.0
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.boolean "saw_onboarding", default: true
    t.integer "score", default: 0
    t.string "secret"
    t.integer "sign_in_count", default: 0, null: false
    t.string "signup_cta_variant"
    t.integer "spent_credits_count", default: 0, null: false
    t.string "stackoverflow_url"
    t.string "stripe_id_code"
    t.integer "subscribed_to_user_subscriptions_count", default: 0, null: false
    t.text "summary"
    t.string "text_color_hex"
    t.string "twitch_url"
    t.datetime "twitter_created_at"
    t.string "twitter_username"
    t.string "unconfirmed_email"
    t.string "unlock_token"
    t.integer "unspent_credits_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "username"
    t.string "website_url"
    t.boolean "welcome_notifications", default: true, null: false
    t.datetime "workshop_expiration"
    t.string "youtube_url"
    t.index "to_tsvector('simple'::regconfig, COALESCE((name)::text, ''::text))", name: "index_users_on_name_as_tsvector", using: :gin
    t.index "to_tsvector('simple'::regconfig, COALESCE((username)::text, ''::text))", name: "index_users_on_username_as_tsvector", using: :gin
    t.index ["apple_username"], name: "index_users_on_apple_username"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["created_at"], name: "index_users_on_created_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["facebook_username"], name: "index_users_on_facebook_username"
    t.index ["feed_fetched_at"], name: "index_users_on_feed_fetched_at"
    t.index ["feed_url"], name: "index_users_on_feed_url", where: "((COALESCE(feed_url, ''::character varying))::text <> ''::text)"
    t.index ["github_username"], name: "index_users_on_github_username", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invitations_count"], name: "index_users_on_invitations_count"
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_users_on_invited_by_type_and_invited_by_id"
    t.index ["old_old_username"], name: "index_users_on_old_old_username"
    t.index ["old_username"], name: "index_users_on_old_username"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["twitter_username"], name: "index_users_on_twitter_username", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
    t.check_constraint "username IS NOT NULL", name: "users_username_not_null"
  end

  create_table "users_gdpr_delete_requests", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.string "email"
    t.datetime "updated_at", precision: 6, null: false
    t.integer "user_id"
    t.string "username"
  end

  create_table "users_notification_settings", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.boolean "email_badge_notifications", default: true, null: false
    t.boolean "email_comment_notifications", default: true, null: false
    t.boolean "email_community_mod_newsletter", default: false, null: false
    t.boolean "email_connect_messages", default: true, null: false
    t.boolean "email_digest_periodic", default: false, null: false
    t.boolean "email_follower_notifications", default: true, null: false
    t.boolean "email_membership_newsletter", default: false, null: false
    t.boolean "email_mention_notifications", default: true, null: false
    t.boolean "email_newsletter", default: false, null: false
    t.boolean "email_tag_mod_newsletter", default: false, null: false
    t.boolean "email_unread_notifications", default: true, null: false
    t.boolean "mobile_comment_notifications", default: true, null: false
    t.boolean "mod_roundrobin_notifications", default: true, null: false
    t.boolean "reaction_notifications", default: true, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "user_id", null: false
    t.boolean "welcome_notifications", default: true, null: false
    t.index ["user_id"], name: "index_users_notification_settings_on_user_id"
  end

  create_table "users_roles", id: false, force: :cascade do |t|
    t.bigint "role_id"
    t.bigint "user_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id"
  end

  create_table "users_settings", force: :cascade do |t|
    t.string "brand_color1", default: "#000000"
    t.string "brand_color2", default: "#ffffff"
    t.integer "config_font", default: 0, null: false
    t.integer "config_navbar", default: 0, null: false
    t.integer "config_theme", default: 0, null: false
    t.datetime "created_at", precision: 6, null: false
    t.boolean "display_announcements", default: true, null: false
    t.boolean "display_email_on_profile", default: false, null: false
    t.boolean "display_sponsors", default: true, null: false
    t.integer "editor_version", default: 0, null: false
    t.integer "experience_level"
    t.boolean "feed_mark_canonical", default: false, null: false
    t.boolean "feed_referential_link", default: true, null: false
    t.string "feed_url"
    t.string "inbox_guidelines"
    t.integer "inbox_type", default: 0, null: false
    t.boolean "permit_adjacent_sponsors", default: true
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_users_settings_on_user_id"
  end

  create_table "users_suspended_usernames", primary_key: "username_hash", id: :string, force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "webhook_endpoints", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "events", null: false, array: true
    t.bigint "oauth_application_id"
    t.string "source"
    t.string "target_url", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["events"], name: "index_webhook_endpoints_on_events"
    t.index ["oauth_application_id"], name: "index_webhook_endpoints_on_oauth_application_id"
    t.index ["target_url"], name: "index_webhook_endpoints_on_target_url", unique: true
    t.index ["user_id"], name: "index_webhook_endpoints_on_user_id"
  end

  create_table "welcome_notifications", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  add_foreign_key "ahoy_events", "ahoy_visits", column: "visit_id", on_delete: :cascade
  add_foreign_key "ahoy_events", "users", on_delete: :cascade
  add_foreign_key "ahoy_messages", "feedback_messages", on_delete: :nullify
  add_foreign_key "ahoy_messages", "users", on_delete: :cascade
  add_foreign_key "ahoy_visits", "users", on_delete: :cascade
  add_foreign_key "api_secrets", "users", on_delete: :cascade
  add_foreign_key "articles", "collections", on_delete: :nullify
  add_foreign_key "articles", "organizations", on_delete: :nullify
  add_foreign_key "articles", "users", on_delete: :cascade
  add_foreign_key "audit_logs", "users"
  add_foreign_key "badge_achievements", "badges"
  add_foreign_key "badge_achievements", "users"
  add_foreign_key "badge_achievements", "users", column: "rewarder_id", on_delete: :nullify
  add_foreign_key "banished_users", "users", column: "banished_by_id", on_delete: :nullify
  add_foreign_key "chat_channel_memberships", "chat_channels"
  add_foreign_key "chat_channel_memberships", "users"
  add_foreign_key "classified_listings", "classified_listing_categories"
  add_foreign_key "classified_listings", "organizations", on_delete: :cascade
  add_foreign_key "classified_listings", "users", on_delete: :cascade
  add_foreign_key "collections", "organizations", on_delete: :nullify
  add_foreign_key "collections", "users", on_delete: :cascade
  add_foreign_key "comments", "users", on_delete: :cascade
  add_foreign_key "credits", "organizations", on_delete: :restrict
  add_foreign_key "credits", "users", on_delete: :cascade
  add_foreign_key "custom_profile_fields", "profiles", on_delete: :cascade
  add_foreign_key "devices", "consumer_apps"
  add_foreign_key "devices", "users"
  add_foreign_key "display_ad_events", "display_ads", on_delete: :cascade
  add_foreign_key "display_ad_events", "users", on_delete: :cascade
  add_foreign_key "display_ads", "organizations", on_delete: :cascade
  add_foreign_key "email_authorizations", "users", on_delete: :cascade
  add_foreign_key "feedback_messages", "users", column: "affected_id", on_delete: :nullify
  add_foreign_key "feedback_messages", "users", column: "offender_id", on_delete: :nullify
  add_foreign_key "feedback_messages", "users", column: "reporter_id", on_delete: :nullify
  add_foreign_key "github_repos", "users", on_delete: :cascade
  add_foreign_key "html_variant_successes", "articles", on_delete: :nullify
  add_foreign_key "html_variant_successes", "html_variants", on_delete: :cascade
  add_foreign_key "html_variant_trials", "articles", on_delete: :nullify
  add_foreign_key "html_variant_trials", "html_variants", on_delete: :cascade
  add_foreign_key "html_variants", "users", on_delete: :cascade
  add_foreign_key "identities", "users", on_delete: :cascade
  add_foreign_key "mentions", "users", on_delete: :cascade
  add_foreign_key "messages", "chat_channels"
  add_foreign_key "messages", "users"
  add_foreign_key "notes", "users", column: "author_id", on_delete: :nullify
  add_foreign_key "notification_subscriptions", "users", on_delete: :cascade
  add_foreign_key "notifications", "organizations", on_delete: :cascade
  add_foreign_key "notifications", "users", on_delete: :cascade
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_grants", "users", column: "resource_owner_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "users", column: "resource_owner_id"
  add_foreign_key "organization_memberships", "organizations", on_delete: :cascade
  add_foreign_key "organization_memberships", "users", on_delete: :cascade
  add_foreign_key "page_views", "articles", on_delete: :cascade
  add_foreign_key "page_views", "users", on_delete: :nullify
  add_foreign_key "podcast_episode_appearances", "podcast_episodes"
  add_foreign_key "podcast_episode_appearances", "users"
  add_foreign_key "podcast_episodes", "podcasts", on_delete: :cascade
  add_foreign_key "podcast_ownerships", "podcasts"
  add_foreign_key "podcast_ownerships", "users"
  add_foreign_key "podcasts", "users", column: "creator_id"
  add_foreign_key "poll_options", "polls", on_delete: :cascade
  add_foreign_key "poll_skips", "polls", on_delete: :cascade
  add_foreign_key "poll_skips", "users", on_delete: :cascade
  add_foreign_key "poll_votes", "poll_options", on_delete: :cascade
  add_foreign_key "poll_votes", "polls", on_delete: :cascade
  add_foreign_key "poll_votes", "users", on_delete: :cascade
  add_foreign_key "polls", "articles", on_delete: :cascade
  add_foreign_key "profile_fields", "profile_field_groups"
  add_foreign_key "profiles", "users", on_delete: :cascade
  add_foreign_key "rating_votes", "articles", on_delete: :cascade
  add_foreign_key "rating_votes", "users", on_delete: :nullify
  add_foreign_key "reactions", "users", on_delete: :cascade
  add_foreign_key "response_templates", "users"
  add_foreign_key "sponsorships", "organizations"
  add_foreign_key "sponsorships", "users"
  add_foreign_key "tag_adjustments", "articles", on_delete: :cascade
  add_foreign_key "tag_adjustments", "tags", on_delete: :cascade
  add_foreign_key "tag_adjustments", "users", on_delete: :cascade
  add_foreign_key "taggings", "tags", on_delete: :cascade
  add_foreign_key "tags", "badges", on_delete: :nullify
  add_foreign_key "tags", "chat_channels", column: "mod_chat_channel_id", on_delete: :nullify
  add_foreign_key "tweets", "users", on_delete: :nullify
  add_foreign_key "user_blocks", "users", column: "blocked_id"
  add_foreign_key "user_blocks", "users", column: "blocker_id"
  add_foreign_key "user_subscriptions", "users", column: "author_id"
  add_foreign_key "user_subscriptions", "users", column: "subscriber_id"
  add_foreign_key "users_notification_settings", "users"
  add_foreign_key "users_roles", "roles", on_delete: :cascade
  add_foreign_key "users_roles", "users", on_delete: :cascade
  add_foreign_key "users_settings", "users"
  add_foreign_key "webhook_endpoints", "oauth_applications"
  add_foreign_key "webhook_endpoints", "users"
  create_trigger("update_reading_list_document", :generated => true, :compatibility => 1).
      on("articles").
      name("update_reading_list_document").
      before(:insert, :update).
      for_each(:row).
      declare("l_org_vector tsvector; l_user_vector tsvector") do
    <<-SQL_ACTIONS
NEW.reading_list_document :=
  to_tsvector('simple'::regconfig, unaccent(coalesce(NEW.body_markdown, ''))) ||
  to_tsvector('simple'::regconfig, unaccent(coalesce(NEW.cached_tag_list, ''))) ||
  to_tsvector('simple'::regconfig, unaccent(coalesce(NEW.cached_user_name, ''))) ||
  to_tsvector('simple'::regconfig, unaccent(coalesce(NEW.cached_user_username, ''))) ||
  to_tsvector('simple'::regconfig, unaccent(coalesce(NEW.title, ''))) ||
  to_tsvector('simple'::regconfig,
    unaccent(
      coalesce(
        array_to_string(
          -- cached_organization is serialized to the DB as a YAML string, we extract only the name attribute
          regexp_match(NEW.cached_organization, 'name: (.*)$', 'n'),
          ' '
        ),
        ''
      )
    )
  );
    SQL_ACTIONS
  end

end
