# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_12_27_114543) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "ahoy_messages", id: :serial, force: :cascade do |t|
    t.string "token"
    t.text "to"
    t.integer "user_id"
    t.string "user_type"
    t.string "mailer"
    t.text "subject"
    t.text "content"
    t.string "utm_source"
    t.string "utm_medium"
    t.string "utm_term"
    t.string "utm_content"
    t.string "utm_campaign"
    t.datetime "sent_at"
    t.datetime "opened_at"
    t.datetime "clicked_at"
    t.integer "feedback_message_id"
    t.index ["to"], name: "index_ahoy_messages_on_to"
    t.index ["token"], name: "index_ahoy_messages_on_token"
    t.index ["user_id", "user_type"], name: "index_ahoy_messages_on_user_id_and_user_type"
  end

  create_table "api_secrets", force: :cascade do |t|
    t.string "secret"
    t.integer "user_id"
    t.string "description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["secret"], name: "index_api_secrets_on_secret", unique: true
    t.index ["user_id"], name: "index_api_secrets_on_user_id"
  end

  create_table "articles", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "title"
    t.text "body_html"
    t.text "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "main_image"
    t.string "description"
    t.boolean "published", default: false
    t.string "password"
    t.datetime "published_at"
    t.boolean "featured", default: false
    t.text "processed_html"
    t.integer "featured_number"
    t.string "social_image"
    t.boolean "allow_small_edits", default: true
    t.boolean "allow_big_edits", default: true
    t.text "body_markdown"
    t.integer "organization_id"
    t.string "canonical_url"
    t.integer "collection_id"
    t.integer "collection_position"
    t.string "name_within_collection"
    t.boolean "show_comments", default: true
    t.string "main_image_background_hex_color", default: "#dddddd"
    t.string "ids_for_suggested_articles", default: "[]"
    t.boolean "receive_notifications", default: true
    t.boolean "approved", default: false
    t.float "amount_due", default: 0.0
    t.float "amount_paid", default: 0.0
    t.boolean "paid", default: false
    t.boolean "removed_for_abuse", default: false
    t.string "abuse_removal_reason"
    t.boolean "published_from_feed", default: false
    t.integer "comments_count", default: 0, null: false
    t.integer "reactions_count", default: 0, null: false
    t.string "video"
    t.string "video_code"
    t.string "video_source_url"
    t.string "video_thumbnail_url"
    t.string "video_closed_caption_track_url"
    t.integer "hotness_score", default: 0
    t.string "feed_source_url"
    t.string "main_tag_name_for_social"
    t.integer "second_user_id"
    t.integer "third_user_id"
    t.integer "positive_reactions_count", default: 0, null: false
    t.datetime "last_buffered"
    t.datetime "edited_at"
    t.datetime "crossposted_at"
    t.boolean "automatically_renew", default: false
    t.datetime "last_invoiced_at"
    t.boolean "live_now", default: false
    t.decimal "lat", precision: 10, scale: 6
    t.decimal "long", precision: 10, scale: 6
    t.integer "spaminess_rating", default: 0
    t.string "language"
    t.integer "job_opportunity_id"
    t.datetime "facebook_last_buffered"
    t.string "cached_tag_list"
    t.string "path"
    t.string "cached_user_name"
    t.string "cached_user_username"
    t.datetime "last_comment_at", default: "2017-01-01 05:00:00"
    t.boolean "email_digest_eligible", default: true
    t.jsonb "boost_states", default: {}, null: false
    t.string "video_state"
    t.integer "reading_time", default: 0
    t.integer "page_views_count", default: 0
    t.integer "previous_positive_reactions_count", default: 0
    t.integer "score", default: 0
    t.integer "featured_impressions", default: 0
    t.float "featured_clickthrough_rate", default: 0.0
    t.string "comment_template"
    t.float "video_duration_in_seconds", default: 0.0
    t.float "experience_level_rating", default: 5.0
    t.float "experience_level_rating_distribution", default: 5.0
    t.datetime "last_experience_level_rating_at"
    t.integer "rating_votes_count", default: 0, null: false
    t.datetime "originally_published_at"
    t.integer "organic_page_views_count", default: 0
    t.integer "organic_page_views_past_month_count", default: 0
    t.integer "organic_page_views_past_week_count", default: 0
    t.text "cached_user"
    t.text "cached_organization"
    t.boolean "archived", default: false
    t.boolean "any_comments_hidden", default: false
    t.integer "nth_published_by_author", default: 0
    t.index ["boost_states"], name: "index_articles_on_boost_states", using: :gin
    t.index ["featured_number"], name: "index_articles_on_featured_number"
    t.index ["feed_source_url"], name: "index_articles_on_feed_source_url"
    t.index ["hotness_score"], name: "index_articles_on_hotness_score"
    t.index ["path"], name: "index_articles_on_path"
    t.index ["published"], name: "index_articles_on_published"
    t.index ["published_at"], name: "index_articles_on_published_at"
    t.index ["slug"], name: "index_articles_on_slug"
    t.index ["user_id"], name: "index_articles_on_user_id"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.bigint "user_id"
    t.string "roles", array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.string "category"
    t.jsonb "data", default: {}, null: false
    t.index ["data"], name: "index_audit_logs_on_data", using: :gin
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "backup_data", force: :cascade do |t|
    t.bigint "instance_id", null: false
    t.string "instance_type", null: false
    t.bigint "instance_user_id"
    t.jsonb "json_data", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "badge_achievements", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "rewarder_id"
    t.bigint "badge_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "rewarding_context_message"
    t.text "rewarding_context_message_markdown"
    t.index ["badge_id"], name: "index_badge_achievements_on_badge_id"
    t.index ["user_id", "badge_id"], name: "index_badge_achievements_on_user_id_and_badge_id"
    t.index ["user_id"], name: "index_badge_achievements_on_user_id"
  end

  create_table "badges", force: :cascade do |t|
    t.string "title", null: false
    t.string "slug", null: false
    t.string "description", null: false
    t.string "badge_image"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["title"], name: "index_badges_on_title", unique: true
  end

  create_table "blocks", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.text "input_html"
    t.text "processed_html"
    t.text "published_html"
    t.text "input_css"
    t.text "processed_css"
    t.text "published_css"
    t.text "input_javascript"
    t.text "processed_javascript"
    t.text "published_javascript"
    t.string "title"
    t.text "body_markdown"
    t.text "body_html"
    t.boolean "featured"
    t.integer "featured_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "index_position"
  end

  create_table "broadcasts", id: :serial, force: :cascade do |t|
    t.string "title"
    t.text "body_markdown"
    t.text "processed_html"
    t.boolean "sent", default: false
    t.string "type_of"
  end

  create_table "buffer_updates", force: :cascade do |t|
    t.integer "article_id", null: false
    t.integer "tag_id"
    t.text "body_text"
    t.string "buffer_profile_id_code"
    t.string "buffer_id_code"
    t.string "social_service_name"
    t.text "buffer_response", default: "--- {}\n"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "composer_user_id"
    t.integer "approver_user_id"
    t.string "status", default: "pending"
  end

  create_table "chat_channel_memberships", force: :cascade do |t|
    t.bigint "chat_channel_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_opened_at", default: "2017-01-01 05:00:00"
    t.boolean "has_unopened_messages", default: false
    t.string "status", default: "active"
    t.string "role", default: "member"
    t.boolean "show_global_badge_notification", default: true
    t.index ["chat_channel_id"], name: "index_chat_channel_memberships_on_chat_channel_id"
    t.index ["user_id", "chat_channel_id"], name: "index_chat_channel_memberships_on_user_id_and_chat_channel_id"
    t.index ["user_id"], name: "index_chat_channel_memberships_on_user_id"
  end

  create_table "chat_channels", force: :cascade do |t|
    t.string "channel_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "channel_name"
    t.string "slug"
    t.datetime "last_message_at", default: "2017-01-01 05:00:00"
    t.string "status", default: "active"
    t.string "description"
  end

  create_table "classified_listings", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "organization_id"
    t.string "title"
    t.text "body_markdown"
    t.text "processed_html"
    t.string "category"
    t.string "cached_tag_list"
    t.datetime "bumped_at"
    t.boolean "published"
    t.boolean "contact_via_connect", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.datetime "last_buffered"
    t.string "location"
    t.datetime "expires_at"
    t.index ["organization_id"], name: "index_classified_listings_on_organization_id"
    t.index ["user_id"], name: "index_classified_listings_on_user_id"
  end

  create_table "collections", id: :serial, force: :cascade do |t|
    t.string "title"
    t.string "slug"
    t.string "description"
    t.string "main_image"
    t.string "social_image"
    t.integer "user_id"
    t.integer "organization_id"
    t.boolean "published", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_collections_on_organization_id"
    t.index ["user_id"], name: "index_collections_on_user_id"
  end

  create_table "comments", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.text "body_html"
    t.boolean "edited", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "ancestry"
    t.string "id_code"
    t.integer "commentable_id"
    t.string "commentable_type"
    t.integer "score", default: 0
    t.boolean "deleted", default: false
    t.boolean "receive_notifications", default: true
    t.integer "markdown_character_count"
    t.datetime "edited_at"
    t.integer "reactions_count", default: 0, null: false
    t.text "body_markdown"
    t.text "processed_html"
    t.integer "positive_reactions_count", default: 0, null: false
    t.integer "spaminess_rating", default: 0
    t.boolean "hidden_by_commentable_user", default: false
    t.index ["ancestry"], name: "index_comments_on_ancestry"
    t.index ["commentable_id", "commentable_type"], name: "index_comments_on_commentable_id_and_commentable_type"
    t.index ["created_at"], name: "index_comments_on_created_at"
    t.index ["score"], name: "index_comments_on_score"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "credits", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "organization_id"
    t.float "cost", default: 0.0
    t.boolean "spent", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "purchase_id"
    t.string "purchase_type"
    t.datetime "spent_at"
    t.index ["purchase_id", "purchase_type"], name: "index_credits_on_purchase_id_and_purchase_type"
    t.index ["spent"], name: "index_credits_on_spent"
  end

  create_table "delayed_jobs", id: :serial, force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "display_ad_events", force: :cascade do |t|
    t.integer "display_ad_id"
    t.integer "user_id"
    t.string "category"
    t.string "context_type"
    t.bigint "context_id"
    t.integer "counts_for", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["display_ad_id"], name: "index_display_ad_events_on_display_ad_id"
    t.index ["user_id"], name: "index_display_ad_events_on_user_id"
  end

  create_table "display_ads", force: :cascade do |t|
    t.integer "organization_id"
    t.string "placement_area"
    t.text "body_markdown"
    t.text "processed_html"
    t.float "cost_per_impression", default: 0.0
    t.float "cost_per_click", default: 0.0
    t.integer "impressions_count", default: 0
    t.integer "clicks_count", default: 0
    t.boolean "published", default: false
    t.boolean "approved", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "success_rate", default: 0.0
  end

  create_table "events", force: :cascade do |t|
    t.string "title"
    t.string "category"
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.string "location_name"
    t.string "location_url"
    t.string "cover_image"
    t.text "description_markdown"
    t.text "description_html"
    t.boolean "published"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.boolean "live_now", default: false
    t.string "profile_image"
    t.string "host_name"
  end

  create_table "feedback_messages", force: :cascade do |t|
    t.text "message"
    t.string "feedback_type"
    t.string "category"
    t.integer "reporter_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "status", default: "Open"
    t.string "reported_url"
    t.integer "offender_id"
    t.integer "affected_id"
    t.index ["affected_id"], name: "index_feedback_messages_on_affected_id"
    t.index ["offender_id"], name: "index_feedback_messages_on_offender_id"
    t.index ["reporter_id"], name: "index_feedback_messages_on_reporter_id"
  end

  create_table "follows", id: :serial, force: :cascade do |t|
    t.string "followable_type", null: false
    t.integer "followable_id", null: false
    t.string "follower_type", null: false
    t.integer "follower_id", null: false
    t.boolean "blocked", default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float "points", default: 1.0
    t.string "subscription_status", default: "all_articles", null: false
    t.index ["created_at"], name: "index_follows_on_created_at"
    t.index ["followable_id", "followable_type"], name: "fk_followables"
    t.index ["follower_id", "follower_type"], name: "fk_follows"
  end

  create_table "github_issues", id: :serial, force: :cascade do |t|
    t.string "url"
    t.string "category"
    t.string "issue_serialized", default: "--- {}\n"
    t.string "processed_html"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "github_repos", force: :cascade do |t|
    t.integer "user_id"
    t.string "name"
    t.string "description"
    t.string "language"
    t.string "url"
    t.integer "bytes_size"
    t.integer "watchers_count"
    t.integer "stargazers_count"
    t.boolean "featured", default: false
    t.integer "priority", default: 0
    t.string "additional_note"
    t.text "info_hash", default: "--- {}\n"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "fork", default: false
    t.integer "github_id_code"
  end

  create_table "html_variant_successes", force: :cascade do |t|
    t.integer "html_variant_id"
    t.integer "article_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["html_variant_id", "article_id"], name: "index_html_variant_successes_on_html_variant_id_and_article_id"
  end

  create_table "html_variant_trials", force: :cascade do |t|
    t.integer "html_variant_id"
    t.integer "article_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["html_variant_id", "article_id"], name: "index_html_variant_trials_on_html_variant_id_and_article_id"
  end

  create_table "html_variants", force: :cascade do |t|
    t.integer "user_id"
    t.string "group"
    t.string "name"
    t.text "html"
    t.string "target_tag"
    t.float "success_rate", default: 0.0
    t.boolean "published", default: false
    t.boolean "approved", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "identities", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "provider"
    t.string "uid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "token"
    t.string "secret"
    t.text "auth_data_dump"
    t.index ["provider", "uid"], name: "index_identities_on_provider_and_uid", unique: true
    t.index ["provider", "user_id"], name: "index_identities_on_provider_and_user_id", unique: true
  end

  create_table "job_opportunities", force: :cascade do |t|
    t.string "remoteness"
    t.string "experience_level"
    t.string "time_commitment"
    t.string "permanency"
    t.string "location_given"
    t.string "location_city"
    t.string "location_country_code"
    t.string "location_postal_code"
    t.decimal "location_lat", precision: 10, scale: 6
    t.decimal "location_long", precision: 10, scale: 6
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "mentions", id: :serial, force: :cascade do |t|
    t.integer "mentionable_id"
    t.string "mentionable_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "messages", force: :cascade do |t|
    t.string "message_html", null: false
    t.string "message_markdown", null: false
    t.bigint "user_id", null: false
    t.bigint "chat_channel_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "edited_at"
    t.index ["chat_channel_id"], name: "index_messages_on_chat_channel_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "notes", id: :serial, force: :cascade do |t|
    t.integer "noteable_id"
    t.text "content"
    t.string "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "noteable_type"
    t.integer "author_id"
  end

  create_table "notification_subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "notifiable_id", null: false
    t.string "notifiable_type", null: false
    t.text "config", default: "all_comments", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notifiable_id", "notifiable_type", "config"], name: "index_notification_subscriptions_on_notifiable_and_config"
  end

  create_table "notifications", id: :serial, force: :cascade do |t|
    t.integer "notifiable_id"
    t.integer "user_id"
    t.string "notifiable_type"
    t.string "action"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "json_data"
    t.boolean "read", default: false
    t.datetime "notified_at"
    t.bigint "organization_id"
    t.index ["created_at"], name: "index_notifications_on_created_at"
    t.index ["json_data"], name: "index_notifications_on_json_data", using: :gin
    t.index ["notifiable_id"], name: "index_notifications_on_notifiable_id"
    t.index ["notifiable_type"], name: "index_notifications_on_notifiable_type"
    t.index ["notified_at"], name: "index_notifications_on_notified_at"
    t.index ["organization_id", "notifiable_id", "notifiable_type", "action"], name: "index_notifications_on_org_notifiable_and_action_not_null", unique: true, where: "(action IS NOT NULL)"
    t.index ["organization_id", "notifiable_id", "notifiable_type"], name: "index_notifications_on_org_notifiable_action_is_null", unique: true, where: "(action IS NULL)"
    t.index ["organization_id"], name: "index_notifications_on_organization_id"
    t.index ["user_id", "notifiable_id", "notifiable_type", "action"], name: "index_notifications_on_user_notifiable_and_action_not_null", unique: true, where: "(action IS NOT NULL)"
    t.index ["user_id", "notifiable_id", "notifiable_type"], name: "index_notifications_on_user_notifiable_action_is_null", unique: true, where: "(action IS NULL)"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.bigint "resource_owner_id", null: false
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "scopes"
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["resource_owner_id"], name: "index_oauth_access_grants_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.bigint "resource_owner_id"
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.string "scopes"
    t.string "previous_refresh_token", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "organization_memberships", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "organization_id", null: false
    t.string "user_title"
    t.string "type_of_user", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "organization_id"], name: "index_organization_memberships_on_user_id_and_organization_id", unique: true
  end

  create_table "organizations", id: :serial, force: :cascade do |t|
    t.string "name"
    t.text "summary"
    t.string "profile_image"
    t.string "url"
    t.string "twitter_username"
    t.string "jobs_url"
    t.string "jobs_email"
    t.string "address"
    t.string "city"
    t.string "state"
    t.string "zip_code"
    t.string "country"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.string "nav_image"
    t.string "github_username"
    t.string "bg_color_hex"
    t.string "text_color_hex"
    t.string "secret"
    t.text "proof"
    t.boolean "approved", default: false
    t.string "email"
    t.string "location"
    t.string "company_size"
    t.string "tech_stack"
    t.string "story"
    t.string "tag_line"
    t.string "cta_button_text"
    t.string "cta_button_url"
    t.text "cta_body_markdown"
    t.text "cta_processed_html"
    t.string "old_slug"
    t.string "old_old_slug"
    t.datetime "last_article_at", default: "2017-01-01 05:00:00"
    t.datetime "profile_updated_at", default: "2017-01-01 05:00:00"
    t.string "dark_nav_image"
    t.integer "credits_count", default: 0, null: false
    t.integer "spent_credits_count", default: 0, null: false
    t.integer "unspent_credits_count", default: 0, null: false
    t.integer "articles_count", default: 0, null: false
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
  end

  create_table "page_views", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "article_id"
    t.integer "counts_for_number_of_views", default: 1
    t.integer "time_tracked_in_seconds", default: 15
    t.string "referrer"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "domain"
    t.string "path"
    t.index ["article_id"], name: "index_page_views_on_article_id"
    t.index ["created_at"], name: "index_page_views_on_created_at"
    t.index ["domain"], name: "index_page_views_on_domain"
    t.index ["user_id"], name: "index_page_views_on_user_id"
  end

  create_table "pages", force: :cascade do |t|
    t.string "title"
    t.text "body_markdown"
    t.text "body_html"
    t.text "processed_html"
    t.string "slug"
    t.string "description"
    t.string "social_image"
    t.string "template"
    t.string "group"
    t.integer "group_order_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_top_level_path", default: false
    t.index ["slug"], name: "index_pages_on_slug", unique: true
  end

  create_table "podcast_episodes", id: :serial, force: :cascade do |t|
    t.integer "podcast_id"
    t.string "title", null: false
    t.string "subtitle"
    t.text "summary"
    t.string "media_url", null: false
    t.string "website_url"
    t.string "itunes_url"
    t.string "image"
    t.integer "duration_in_seconds"
    t.datetime "published_at"
    t.string "slug", null: false
    t.string "guid", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "deepgram_id_code"
    t.text "body"
    t.text "quote"
    t.string "social_image"
    t.integer "featured_number"
    t.boolean "featured", default: true
    t.string "order_key"
    t.text "processed_html"
    t.integer "comments_count", default: 0, null: false
    t.integer "reactions_count", default: 0, null: false
    t.boolean "reachable", default: true
    t.string "status_notice"
    t.boolean "https", default: true
    t.boolean "any_comments_hidden", default: false
    t.index ["guid"], name: "index_podcast_episodes_on_guid", unique: true
    t.index ["media_url"], name: "index_podcast_episodes_on_media_url", unique: true
    t.index ["podcast_id"], name: "index_podcast_episodes_on_podcast_id"
  end

  create_table "podcasts", id: :serial, force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.string "feed_url", null: false
    t.string "itunes_url"
    t.string "image", null: false
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "twitter_username"
    t.string "website_url"
    t.string "main_color_hex", null: false
    t.string "overcast_url"
    t.string "android_url"
    t.string "pattern_image"
    t.string "soundcloud_url"
    t.text "status_notice", default: ""
    t.boolean "unique_website_url?", default: true
    t.boolean "reachable", default: true
    t.boolean "published", default: false
    t.index ["feed_url"], name: "index_podcasts_on_feed_url", unique: true
    t.index ["slug"], name: "index_podcasts_on_slug", unique: true
  end

  create_table "poll_options", force: :cascade do |t|
    t.bigint "poll_id"
    t.string "markdown"
    t.string "processed_html"
    t.boolean "counts_in_tabulation"
    t.integer "poll_votes_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "poll_skips", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "poll_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["poll_id", "user_id"], name: "index_poll_skips_on_poll_and_user", unique: true
  end

  create_table "poll_votes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "poll_id", null: false
    t.bigint "poll_option_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["poll_option_id", "user_id"], name: "index_poll_votes_on_poll_option_and_user", unique: true
  end

  create_table "polls", force: :cascade do |t|
    t.bigint "article_id"
    t.string "prompt_markdown"
    t.string "prompt_html"
    t.boolean "allow_multiple_selections", default: false
    t.integer "poll_options_count", default: 0, null: false
    t.integer "poll_votes_count", default: 0, null: false
    t.integer "poll_skips_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "pro_memberships", force: :cascade do |t|
    t.bigint "user_id"
    t.string "status", default: "active"
    t.datetime "expires_at", null: false
    t.datetime "expiration_notification_at"
    t.integer "expiration_notifications_count", default: 0, null: false
    t.boolean "auto_recharge", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["auto_recharge"], name: "index_pro_memberships_on_auto_recharge"
    t.index ["expires_at"], name: "index_pro_memberships_on_expires_at"
    t.index ["status"], name: "index_pro_memberships_on_status"
    t.index ["user_id"], name: "index_pro_memberships_on_user_id"
  end

  create_table "profile_pins", force: :cascade do |t|
    t.bigint "profile_id"
    t.bigint "pinnable_id"
    t.string "profile_type"
    t.string "pinnable_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pinnable_id"], name: "index_profile_pins_on_pinnable_id"
    t.index ["profile_id"], name: "index_profile_pins_on_profile_id"
  end

  create_table "rating_votes", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "article_id"
    t.string "group"
    t.float "rating"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id"], name: "index_rating_votes_on_article_id"
    t.index ["user_id"], name: "index_rating_votes_on_user_id"
  end

  create_table "reactions", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "reactable_id"
    t.string "reactable_type"
    t.string "category"
    t.float "points", default: 1.0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "valid"
    t.index ["category"], name: "index_reactions_on_category"
    t.index ["created_at"], name: "index_reactions_on_created_at"
    t.index ["points"], name: "index_reactions_on_points"
    t.index ["reactable_id"], name: "index_reactions_on_reactable_id"
    t.index ["reactable_type"], name: "index_reactions_on_reactable_type"
    t.index ["user_id"], name: "index_reactions_on_user_id"
  end

  create_table "roles", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "resource_type"
    t.integer "resource_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"
    t.index ["name"], name: "index_roles_on_name"
  end

  create_table "site_configs", force: :cascade do |t|
    t.string "var", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["var"], name: "index_site_configs_on_var", unique: true
  end

  create_table "sponsorships", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "organization_id"
    t.string "level", null: false
    t.string "status", default: "none", null: false
    t.datetime "expires_at"
    t.text "blurb_html"
    t.integer "featured_number", default: 0, null: false
    t.text "instructions"
    t.datetime "instructions_updated_at"
    t.string "tagline"
    t.string "url"
    t.bigint "sponsorable_id"
    t.string "sponsorable_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["level"], name: "index_sponsorships_on_level"
    t.index ["organization_id"], name: "index_sponsorships_on_organization_id"
    t.index ["sponsorable_id", "sponsorable_type"], name: "index_sponsorships_on_sponsorable_id_and_sponsorable_type"
    t.index ["status"], name: "index_sponsorships_on_status"
    t.index ["user_id"], name: "index_sponsorships_on_user_id"
  end

  create_table "tag_adjustments", force: :cascade do |t|
    t.integer "user_id"
    t.integer "article_id"
    t.integer "tag_id"
    t.string "tag_name"
    t.string "adjustment_type"
    t.string "status"
    t.string "reason_for_adjustment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "taggings", id: :serial, force: :cascade do |t|
    t.integer "tag_id"
    t.string "taggable_type"
    t.integer "taggable_id"
    t.string "tagger_type"
    t.integer "tagger_id"
    t.string "context", limit: 128
    t.datetime "created_at"
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

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "taggings_count", default: 0
    t.text "wiki_body_markdown"
    t.text "wiki_body_html"
    t.text "rules_markdown"
    t.text "rules_html"
    t.string "short_summary"
    t.boolean "requires_approval", default: false
    t.text "submission_template"
    t.string "submission_rules_headsup"
    t.string "pretty_name"
    t.string "profile_image"
    t.string "bg_color_hex"
    t.string "text_color_hex"
    t.string "social_image"
    t.string "alias_for"
    t.boolean "supported", default: false
    t.string "keywords_for_search"
    t.integer "hotness_score", default: 0
    t.string "buffer_profile_id_code"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "badge_id"
    t.string "category", default: "uncategorized", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "tweets", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "favorite_count"
    t.integer "retweet_count"
    t.integer "twitter_user_following_count"
    t.integer "twitter_user_followers_count"
    t.string "in_reply_to_user_id_code"
    t.string "in_reply_to_status_id_code"
    t.string "twitter_uid"
    t.string "twitter_username"
    t.string "twitter_id_code"
    t.string "quoted_tweet_id_code"
    t.string "in_reply_to_username"
    t.string "source"
    t.string "text"
    t.string "twitter_name"
    t.string "mentioned_usernames_serialized", default: "--- []\n"
    t.string "hashtags_serialized", default: "--- []\n"
    t.string "primary_external_url"
    t.string "profile_image"
    t.text "urls_serialized", default: "--- []\n"
    t.text "media_serialized", default: "--- []\n"
    t.text "extended_entities_serialized", default: "--- {}\n"
    t.text "full_fetched_object_serialized", default: "--- {}\n"
    t.datetime "tweeted_at"
    t.datetime "last_fetched_at"
    t.boolean "user_is_verified"
    t.boolean "is_quote_status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_blocks", force: :cascade do |t|
    t.bigint "blocked_id", null: false
    t.bigint "blocker_id", null: false
    t.string "config", default: "default", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["blocked_id", "blocker_id"], name: "index_user_blocks_on_blocked_id_and_blocker_id", unique: true
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "twitter_username"
    t.string "github_username"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "profile_image"
    t.string "email"
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "organization_id"
    t.boolean "org_admin", default: false
    t.text "base_cover_letter"
    t.text "resume_html"
    t.text "summary"
    t.string "website_url"
    t.string "username"
    t.string "remember_token"
    t.string "secret"
    t.boolean "email_newsletter", default: true
    t.boolean "email_comment_notifications", default: true
    t.string "bg_color_hex"
    t.string "text_color_hex"
    t.string "employer_name"
    t.string "employer_url"
    t.string "employment_title"
    t.string "currently_learning"
    t.string "mostly_work_with"
    t.string "available_for"
    t.string "currently_hacking_on"
    t.string "location"
    t.boolean "email_public", default: false
    t.string "education"
    t.float "reputation_modifier", default: 1.0
    t.integer "score", default: 0
    t.boolean "email_follower_notifications", default: true
    t.string "signup_cta_variant"
    t.string "signup_refer_code"
    t.string "signup_referring_site"
    t.string "top_languages"
    t.integer "experience_level"
    t.string "specialty"
    t.string "tabs_or_spaces"
    t.string "shipping_name"
    t.string "shipping_company"
    t.string "shipping_address"
    t.string "shipping_address_line_2"
    t.string "shipping_city"
    t.string "shipping_state"
    t.string "shipping_country"
    t.string "shipping_postal_code"
    t.string "shirt_gender"
    t.string "shirt_size"
    t.boolean "onboarding_package_requested", default: false
    t.boolean "onboarding_package_fulfilled", default: false
    t.datetime "github_created_at"
    t.datetime "twitter_created_at"
    t.integer "twitter_following_count"
    t.integer "twitter_followers_count"
    t.datetime "onboarding_package_form_submmitted_at"
    t.datetime "personal_data_updated_at"
    t.string "feed_url"
    t.integer "articles_count", default: 0, null: false
    t.integer "comments_count", default: 0, null: false
    t.string "old_username"
    t.string "old_old_username"
    t.string "text_only_name"
    t.boolean "shipping_validated", default: false
    t.datetime "shipping_validated_at"
    t.boolean "looking_for_work", default: false
    t.boolean "looking_for_work_publicly", default: false
    t.boolean "contact_consent", default: false
    t.integer "reactions_count", default: 0, null: false
    t.boolean "email_unread_notifications", default: true
    t.boolean "onboarding_package_requested_again", default: false
    t.boolean "feed_admin_publish_permission", default: true
    t.boolean "feed_mark_canonical", default: false
    t.datetime "last_moderation_notification", default: "2017-01-01 06:00:00"
    t.datetime "last_notification_activity"
    t.string "stripe_id_code"
    t.boolean "checked_code_of_conduct", default: false
    t.boolean "email_mention_notifications", default: true
    t.integer "following_tags_count", default: 0, null: false
    t.integer "following_users_count", default: 0, null: false
    t.integer "following_orgs_count", default: 0, null: false
    t.jsonb "language_settings", default: {}, null: false
    t.boolean "saw_onboarding", default: true
    t.integer "monthly_dues", default: 0
    t.boolean "display_sponsors", default: true
    t.datetime "membership_started_at"
    t.boolean "email_membership_newsletter", default: false
    t.datetime "workshop_expiration"
    t.boolean "permit_adjacent_sponsors", default: true
    t.boolean "email_digest_periodic", default: true, null: false
    t.datetime "last_followed_at"
    t.integer "badge_achievements_count", default: 0, null: false
    t.boolean "email_badge_notifications", default: true
    t.string "facebook_url"
    t.string "stackoverflow_url"
    t.string "linkedin_url"
    t.string "behance_url"
    t.string "dribbble_url"
    t.boolean "email_connect_messages", default: true
    t.string "editor_version", default: "v1"
    t.string "medium_url"
    t.boolean "export_requested", default: false
    t.datetime "exported_at"
    t.string "gitlab_url"
    t.string "mastodon_url"
    t.boolean "mobile_comment_notifications", default: true
    t.datetime "feed_fetched_at", default: "2017-01-01 05:00:00"
    t.string "inbox_type", default: "private"
    t.datetime "last_article_at", default: "2017-01-01 05:00:00"
    t.datetime "last_comment_at", default: "2017-01-01 05:00:00"
    t.datetime "profile_updated_at", default: "2017-01-01 05:00:00"
    t.datetime "github_repos_updated_at", default: "2017-01-01 05:00:00"
    t.integer "rating_votes_count", default: 0, null: false
    t.string "config_theme", default: "default"
    t.string "config_font", default: "default"
    t.boolean "email_tag_mod_newsletter", default: false
    t.boolean "email_community_mod_newsletter", default: false
    t.string "inbox_guidelines"
    t.string "twitch_username"
    t.string "currently_streaming_on"
    t.string "twitch_url"
    t.integer "credits_count", default: 0, null: false
    t.integer "spent_credits_count", default: 0, null: false
    t.integer "unspent_credits_count", default: 0, null: false
    t.string "onboarding_checklist", default: [], array: true
    t.boolean "checked_terms_and_conditions", default: false
    t.string "instagram_url"
    t.boolean "feed_referential_link", default: true, null: false
    t.string "last_onboarding_page"
    t.string "onboarding_variant_version", default: "0"
    t.boolean "mod_roundrobin_notifications", default: true
    t.bigint "blocked_by_count", default: 0, null: false
    t.bigint "blocking_others_count", default: 0, null: false
    t.string "config_navbar", default: "default", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["created_at"], name: "index_users_on_created_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["github_username"], name: "index_users_on_github_username", unique: true
    t.index ["language_settings"], name: "index_users_on_language_settings", using: :gin
    t.index ["old_old_username"], name: "index_users_on_old_old_username"
    t.index ["old_username"], name: "index_users_on_old_username"
    t.index ["organization_id"], name: "index_users_on_organization_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["twitter_username"], name: "index_users_on_twitter_username", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "users_roles", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id"
  end

  create_table "webhook_endpoints", force: :cascade do |t|
    t.string "target_url", null: false
    t.string "events", null: false, array: true
    t.bigint "user_id", null: false
    t.string "source"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "oauth_application_id"
    t.index ["events"], name: "index_webhook_endpoints_on_events"
    t.index ["oauth_application_id"], name: "index_webhook_endpoints_on_oauth_application_id"
    t.index ["user_id"], name: "index_webhook_endpoints_on_user_id"
  end

  add_foreign_key "api_secrets", "users", on_delete: :cascade
  add_foreign_key "audit_logs", "users"
  add_foreign_key "badge_achievements", "badges"
  add_foreign_key "badge_achievements", "users"
  add_foreign_key "chat_channel_memberships", "chat_channels"
  add_foreign_key "chat_channel_memberships", "users"
  add_foreign_key "classified_listings", "users", on_delete: :cascade
  add_foreign_key "identities", "users", on_delete: :cascade
  add_foreign_key "messages", "chat_channels"
  add_foreign_key "messages", "users"
  add_foreign_key "notification_subscriptions", "users", on_delete: :cascade
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_grants", "users", column: "resource_owner_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "users", column: "resource_owner_id"
  add_foreign_key "page_views", "articles", on_delete: :cascade
  add_foreign_key "pro_memberships", "users"
  add_foreign_key "sponsorships", "organizations"
  add_foreign_key "sponsorships", "users"
  add_foreign_key "tag_adjustments", "articles", on_delete: :cascade
  add_foreign_key "tag_adjustments", "tags", on_delete: :cascade
  add_foreign_key "tag_adjustments", "users", on_delete: :cascade
  add_foreign_key "user_blocks", "users", column: "blocked_id"
  add_foreign_key "user_blocks", "users", column: "blocker_id"
  add_foreign_key "users_roles", "users", on_delete: :cascade
  add_foreign_key "webhook_endpoints", "oauth_applications"
  add_foreign_key "webhook_endpoints", "users"
end
