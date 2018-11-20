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

ActiveRecord::Schema.define(version: 20181120170350) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "ahoy_messages", id: :serial, force: :cascade do |t|
    t.datetime "clicked_at"
    t.text "content"
    t.integer "feedback_message_id"
    t.string "mailer"
    t.datetime "opened_at"
    t.datetime "sent_at"
    t.text "subject"
    t.text "to"
    t.string "token"
    t.integer "user_id"
    t.string "user_type"
    t.string "utm_campaign"
    t.string "utm_content"
    t.string "utm_medium"
    t.string "utm_source"
    t.string "utm_term"
    t.index ["token"], name: "index_ahoy_messages_on_token"
    t.index ["user_id", "user_type"], name: "index_ahoy_messages_on_user_id_and_user_type"
  end

  create_table "articles", id: :serial, force: :cascade do |t|
    t.string "abuse_removal_reason"
    t.boolean "allow_big_edits", default: true
    t.boolean "allow_small_edits", default: true
    t.float "amount_due", default: 0.0
    t.float "amount_paid", default: 0.0
    t.boolean "approved", default: false
    t.boolean "automatically_renew", default: false
    t.text "body_html"
    t.text "body_markdown"
    t.jsonb "boost_states", default: {}, null: false
    t.string "cached_tag_list"
    t.string "cached_user_name"
    t.string "cached_user_username"
    t.string "canonical_url"
    t.integer "collection_id"
    t.integer "collection_position"
    t.integer "comments_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "crossposted_at"
    t.string "description"
    t.datetime "edited_at"
    t.boolean "email_digest_eligible", default: true
    t.datetime "facebook_last_buffered"
    t.boolean "featured", default: false
    t.float "featured_clickthrough_rate", default: 0.0
    t.integer "featured_impressions", default: 0
    t.integer "featured_number"
    t.string "feed_source_url"
    t.integer "hotness_score", default: 0
    t.string "ids_for_suggested_articles", default: "[]"
    t.integer "job_opportunity_id"
    t.string "language"
    t.datetime "last_buffered"
    t.datetime "last_comment_at", default: "2017-01-01 05:00:00"
    t.datetime "last_invoiced_at"
    t.decimal "lat", precision: 10, scale: 6
    t.boolean "live_now", default: false
    t.decimal "long", precision: 10, scale: 6
    t.string "main_image"
    t.string "main_image_background_hex_color", default: "#dddddd"
    t.string "main_tag_name_for_social"
    t.string "name_within_collection"
    t.integer "organization_id"
    t.integer "page_views_count", default: 0
    t.boolean "paid", default: false
    t.string "password"
    t.string "path"
    t.integer "positive_reactions_count", default: 0, null: false
    t.integer "previous_positive_reactions_count", default: 0
    t.text "processed_html"
    t.boolean "published", default: false
    t.datetime "published_at"
    t.boolean "published_from_feed", default: false
    t.integer "reactions_count", default: 0, null: false
    t.boolean "receive_notifications", default: true
    t.boolean "removed_for_abuse", default: false
    t.integer "score", default: 0
    t.integer "second_user_id"
    t.boolean "show_comments", default: true
    t.text "slug"
    t.string "social_image"
    t.integer "spaminess_rating", default: 0
    t.integer "third_user_id"
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.string "video"
    t.string "video_closed_caption_track_url"
    t.string "video_code"
    t.string "video_source_url"
    t.string "video_state"
    t.string "video_thumbnail_url"
    t.index ["boost_states"], name: "index_articles_on_boost_states", using: :gin
    t.index ["featured_number"], name: "index_articles_on_featured_number"
    t.index ["hotness_score"], name: "index_articles_on_hotness_score"
    t.index ["published_at"], name: "index_articles_on_published_at"
    t.index ["slug"], name: "index_articles_on_slug"
    t.index ["user_id"], name: "index_articles_on_user_id"
  end

  create_table "badge_achievements", force: :cascade do |t|
    t.bigint "badge_id", null: false
    t.datetime "created_at", null: false
    t.integer "rewarder_id"
    t.text "rewarding_context_message"
    t.text "rewarding_context_message_markdown"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["badge_id"], name: "index_badge_achievements_on_badge_id"
    t.index ["user_id", "badge_id"], name: "index_badge_achievements_on_user_id_and_badge_id"
    t.index ["user_id"], name: "index_badge_achievements_on_user_id"
  end

  create_table "badges", force: :cascade do |t|
    t.string "badge_image"
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.string "slug", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["title"], name: "index_badges_on_title", unique: true
  end

  create_table "blocks", id: :serial, force: :cascade do |t|
    t.text "body_html"
    t.text "body_markdown"
    t.datetime "created_at", null: false
    t.boolean "featured"
    t.integer "featured_number"
    t.integer "index_position"
    t.text "input_css"
    t.text "input_html"
    t.text "input_javascript"
    t.text "processed_css"
    t.text "processed_html"
    t.text "processed_javascript"
    t.text "published_css"
    t.text "published_html"
    t.text "published_javascript"
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "user_id"
  end

  create_table "broadcasts", id: :serial, force: :cascade do |t|
    t.text "body_markdown"
    t.text "processed_html"
    t.boolean "sent", default: false
    t.string "title"
    t.string "type_of"
  end

  create_table "buffer_updates", force: :cascade do |t|
    t.integer "article_id", null: false
    t.text "body_text"
    t.string "buffer_id_code"
    t.string "buffer_profile_id_code"
    t.text "buffer_response", default: "--- {}\n"
    t.datetime "created_at", null: false
    t.string "social_service_name"
    t.integer "tag_id"
    t.datetime "updated_at", null: false
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
    t.index ["chat_channel_id"], name: "index_chat_channel_memberships_on_chat_channel_id"
    t.index ["user_id", "chat_channel_id"], name: "index_chat_channel_memberships_on_user_id_and_chat_channel_id"
    t.index ["user_id"], name: "index_chat_channel_memberships_on_user_id"
  end

  create_table "chat_channels", force: :cascade do |t|
    t.string "channel_name"
    t.string "channel_type", null: false
    t.datetime "created_at", null: false
    t.string "description"
    t.datetime "last_message_at", default: "2017-01-01 05:00:00"
    t.string "slug"
    t.string "status", default: "active"
    t.datetime "updated_at", null: false
  end

  create_table "collections", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.string "main_image"
    t.integer "organization_id"
    t.boolean "published", default: false
    t.string "slug"
    t.string "social_image"
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["organization_id"], name: "index_collections_on_organization_id"
    t.index ["user_id"], name: "index_collections_on_user_id"
  end

  create_table "comments", id: :serial, force: :cascade do |t|
    t.string "ancestry"
    t.text "body_html"
    t.text "body_markdown"
    t.integer "commentable_id"
    t.string "commentable_type"
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false
    t.boolean "edited", default: false
    t.datetime "edited_at"
    t.string "id_code"
    t.integer "markdown_character_count"
    t.integer "positive_reactions_count", default: 0, null: false
    t.text "processed_html"
    t.integer "reactions_count", default: 0, null: false
    t.boolean "receive_notifications", default: true
    t.integer "score", default: 0
    t.integer "spaminess_rating", default: 0
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["ancestry"], name: "index_comments_on_ancestry"
  end

  create_table "delayed_jobs", id: :serial, force: :cascade do |t|
    t.integer "attempts", default: 0, null: false
    t.datetime "created_at"
    t.datetime "failed_at"
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "locked_at"
    t.string "locked_by"
    t.integer "priority", default: 0, null: false
    t.string "queue"
    t.datetime "run_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "display_ads", force: :cascade do |t|
    t.boolean "approved", default: false
    t.text "body_markdown"
    t.integer "clicks_count", default: 0
    t.float "cost_per_click", default: 0.0
    t.float "cost_per_impression", default: 0.0
    t.datetime "created_at", null: false
    t.integer "impressions_count", default: 0
    t.integer "organization_id"
    t.string "placement_area"
    t.text "processed_html"
    t.boolean "published", default: false
    t.datetime "updated_at", null: false
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
    t.integer "affected_id"
    t.string "category"
    t.datetime "created_at"
    t.string "feedback_type"
    t.text "message"
    t.integer "offender_id"
    t.string "reported_url"
    t.integer "reporter_id"
    t.string "status", default: "Open"
    t.datetime "updated_at"
    t.index ["affected_id"], name: "index_feedback_messages_on_affected_id"
    t.index ["offender_id"], name: "index_feedback_messages_on_offender_id"
    t.index ["reporter_id"], name: "index_feedback_messages_on_reporter_id"
  end

  create_table "flipflop_features", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "enabled", default: false, null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
  end

  create_table "follows", id: :serial, force: :cascade do |t|
    t.boolean "blocked", default: false, null: false
    t.datetime "created_at"
    t.integer "followable_id", null: false
    t.string "followable_type", null: false
    t.integer "follower_id", null: false
    t.string "follower_type", null: false
    t.datetime "updated_at"
    t.index ["followable_id", "followable_type"], name: "fk_followables"
    t.index ["follower_id", "follower_type"], name: "fk_follows"
  end

  create_table "github_issues", id: :serial, force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.string "issue_serialized", default: "--- {}\n"
    t.string "processed_html"
    t.datetime "updated_at", null: false
    t.string "url"
  end

  create_table "github_repos", force: :cascade do |t|
    t.string "additional_note"
    t.integer "bytes_size"
    t.datetime "created_at", null: false
    t.string "description"
    t.boolean "featured", default: false
    t.boolean "fork", default: false
    t.integer "github_id_code"
    t.text "info_hash", default: "--- {}\n"
    t.string "language"
    t.string "name"
    t.integer "priority", default: 0
    t.integer "stargazers_count"
    t.datetime "updated_at", null: false
    t.string "url"
    t.integer "user_id"
    t.integer "watchers_count"
  end

  create_table "html_variant_successes", force: :cascade do |t|
    t.integer "article_id"
    t.datetime "created_at", null: false
    t.integer "html_variant_id"
    t.datetime "updated_at", null: false
    t.index ["html_variant_id", "article_id"], name: "index_html_variant_successes_on_html_variant_id_and_article_id"
  end

  create_table "html_variant_trials", force: :cascade do |t|
    t.integer "article_id"
    t.datetime "created_at", null: false
    t.integer "html_variant_id"
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
    t.integer "user_id"
  end

  create_table "identities", id: :serial, force: :cascade do |t|
    t.text "auth_data_dump"
    t.datetime "created_at", null: false
    t.string "provider"
    t.string "secret"
    t.string "token"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.integer "user_id"
  end

  create_table "job_opportunities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "experience_level"
    t.string "location_city"
    t.string "location_country_code"
    t.string "location_given"
    t.decimal "location_lat", precision: 10, scale: 6
    t.decimal "location_long", precision: 10, scale: 6
    t.string "location_postal_code"
    t.string "permanency"
    t.string "remoteness"
    t.string "time_commitment"
    t.datetime "updated_at", null: false
  end

  create_table "mentions", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "mentionable_id"
    t.string "mentionable_type"
    t.datetime "updated_at", null: false
    t.integer "user_id"
  end

  create_table "mentor_relationships", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.integer "mentee_id", null: false
    t.integer "mentor_id", null: false
    t.datetime "updated_at", null: false
    t.index ["mentee_id", "mentor_id"], name: "index_mentor_relationships_on_mentee_id_and_mentor_id", unique: true
    t.index ["mentee_id"], name: "index_mentor_relationships_on_mentee_id"
    t.index ["mentor_id"], name: "index_mentor_relationships_on_mentor_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "chat_channel_id", null: false
    t.datetime "created_at", null: false
    t.text "encrypted_message_html"
    t.text "encrypted_message_html_iv"
    t.text "encrypted_message_markdown"
    t.text "encrypted_message_markdown_iv"
    t.string "message_html", null: false
    t.string "message_markdown", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["chat_channel_id"], name: "index_messages_on_chat_channel_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "mutes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "mutable_id"
    t.integer "mutable_type"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["user_id", "mutable_id", "mutable_type"], name: "index_mutes_on_user_id_and_mutable_id_and_mutable_type"
  end

  create_table "notes", id: :serial, force: :cascade do |t|
    t.integer "author_id"
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "noteable_id"
    t.string "noteable_type"
    t.string "reason"
    t.datetime "updated_at", null: false
  end

  create_table "notifications", id: :serial, force: :cascade do |t|
    t.string "action"
    t.datetime "created_at", null: false
    t.jsonb "json_data"
    t.integer "notifiable_id"
    t.string "notifiable_type"
    t.datetime "notified_at"
    t.boolean "read", default: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["json_data"], name: "index_notifications_on_json_data", using: :gin
    t.index ["notifiable_id"], name: "index_notifications_on_notifiable_id"
    t.index ["notifiable_type"], name: "index_notifications_on_notifiable_type"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "organizations", id: :serial, force: :cascade do |t|
    t.string "address"
    t.boolean "approved", default: false
    t.string "bg_color_hex"
    t.string "city"
    t.string "company_size"
    t.string "country"
    t.datetime "created_at", null: false
    t.text "cta_body_markdown"
    t.string "cta_button_text"
    t.string "cta_button_url"
    t.text "cta_processed_html"
    t.string "email"
    t.string "github_username"
    t.string "jobs_email"
    t.string "jobs_url"
    t.string "location"
    t.string "name"
    t.string "nav_image"
    t.string "profile_image"
    t.text "proof"
    t.string "secret"
    t.string "slug"
    t.string "state"
    t.string "story"
    t.text "summary"
    t.string "tag_line"
    t.string "tech_stack"
    t.string "text_color_hex"
    t.string "twitter_username"
    t.datetime "updated_at", null: false
    t.string "url"
    t.string "zip_code"
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
  end

  create_table "podcast_episodes", id: :serial, force: :cascade do |t|
    t.text "body"
    t.integer "comments_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "deepgram_id_code"
    t.integer "duration_in_seconds"
    t.boolean "featured", default: true
    t.integer "featured_number"
    t.string "guid"
    t.string "image"
    t.string "itunes_url"
    t.string "media_url"
    t.string "order_key"
    t.integer "podcast_id"
    t.text "processed_html"
    t.datetime "published_at"
    t.text "quote"
    t.integer "reactions_count", default: 0, null: false
    t.string "slug"
    t.string "social_image"
    t.string "subtitle"
    t.text "summary"
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "website_url"
  end

  create_table "podcasts", id: :serial, force: :cascade do |t|
    t.string "android_url"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "feed_url"
    t.string "image"
    t.string "itunes_url"
    t.string "main_color_hex"
    t.string "overcast_url"
    t.string "pattern_image"
    t.string "slug"
    t.string "soundcloud_url"
    t.text "status_notice", default: ""
    t.string "title"
    t.string "twitter_username"
    t.boolean "unique_website_url?", default: true
    t.datetime "updated_at", null: false
    t.string "website_url"
  end

  create_table "push_notification_subscriptions", force: :cascade do |t|
    t.string "auth_key"
    t.datetime "created_at", null: false
    t.string "endpoint"
    t.string "notification_type"
    t.string "p256dh_key"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_push_notification_subscriptions_on_user_id"
  end

  create_table "reactions", id: :serial, force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.float "points", default: 1.0
    t.integer "reactable_id"
    t.string "reactable_type"
    t.string "status", default: "valid"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["category"], name: "index_reactions_on_category"
    t.index ["reactable_id"], name: "index_reactions_on_reactable_id"
    t.index ["reactable_type"], name: "index_reactions_on_reactable_type"
    t.index ["user_id"], name: "index_reactions_on_user_id"
  end

  create_table "roles", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.string "name"
    t.integer "resource_id"
    t.string "resource_type"
    t.datetime "updated_at"
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"
    t.index ["name"], name: "index_roles_on_name"
  end

  create_table "search_keywords", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "google_checked_at"
    t.integer "google_difficulty"
    t.integer "google_position"
    t.string "google_result_path"
    t.integer "google_volume"
    t.string "keyword"
    t.datetime "updated_at", null: false
    t.index ["google_result_path"], name: "index_search_keywords_on_google_result_path"
  end

  create_table "taggings", id: :serial, force: :cascade do |t|
    t.string "context", limit: 128
    t.datetime "created_at"
    t.integer "tag_id"
    t.integer "taggable_id"
    t.string "taggable_type"
    t.integer "tagger_id"
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

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "alias_for"
    t.string "bg_color_hex"
    t.string "buffer_profile_id_code"
    t.integer "hotness_score", default: 0
    t.string "keywords_for_search"
    t.string "name"
    t.string "pretty_name"
    t.string "profile_image"
    t.boolean "requires_approval", default: false
    t.text "rules_html"
    t.text "rules_markdown"
    t.string "short_summary"
    t.string "social_image"
    t.string "submission_rules_headsup"
    t.text "submission_template"
    t.boolean "supported", default: false
    t.integer "taggings_count", default: 0
    t.string "text_color_hex"
    t.text "wiki_body_html"
    t.text "wiki_body_markdown"
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "tweets", id: :serial, force: :cascade do |t|
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
    t.string "primary_external_url"
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
    t.integer "user_id"
    t.boolean "user_is_verified"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.integer "articles_count", default: 0, null: false
    t.string "available_for"
    t.integer "badge_achievements_count", default: 0, null: false
    t.text "base_cover_letter"
    t.string "behance_url"
    t.string "bg_color_hex"
    t.boolean "checked_code_of_conduct", default: false
    t.integer "comments_count", default: 0, null: false
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.boolean "contact_consent", default: false
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.inet "current_sign_in_ip"
    t.string "currently_hacking_on"
    t.string "currently_learning"
    t.boolean "display_sponsors", default: true
    t.string "dribbble_url"
    t.string "editor_version", default: "v1"
    t.string "education"
    t.string "email", default: "", null: false
    t.boolean "email_badge_notifications", default: true
    t.boolean "email_comment_notifications", default: true
    t.boolean "email_connect_messages", default: true
    t.boolean "email_digest_periodic", default: true, null: false
    t.boolean "email_follower_notifications", default: true
    t.boolean "email_membership_newsletter", default: false
    t.boolean "email_mention_notifications", default: true
    t.boolean "email_newsletter", default: true
    t.boolean "email_public", default: false
    t.boolean "email_unread_notifications", default: true
    t.string "employer_name"
    t.string "employer_url"
    t.string "employment_title"
    t.string "encrypted_password", default: "", null: false
    t.integer "experience_level"
    t.boolean "export_requested", default: false
    t.datetime "exported_at"
    t.string "facebook_url"
    t.boolean "feed_admin_publish_permission", default: true
    t.boolean "feed_mark_canonical", default: false
    t.string "feed_url"
    t.integer "following_orgs_count", default: 0, null: false
    t.integer "following_tags_count", default: 0, null: false
    t.integer "following_users_count", default: 0, null: false
    t.datetime "github_created_at"
    t.string "github_username"
    t.string "gitlab_url"
    t.jsonb "language_settings", default: {}, null: false
    t.datetime "last_followed_at"
    t.datetime "last_moderation_notification", default: "2017-01-01 05:00:00"
    t.datetime "last_notification_activity"
    t.datetime "last_sign_in_at"
    t.inet "last_sign_in_ip"
    t.string "linkedin_url"
    t.string "location"
    t.boolean "looking_for_work", default: false
    t.boolean "looking_for_work_publicly", default: false
    t.string "medium_url"
    t.datetime "membership_started_at"
    t.text "mentee_description"
    t.datetime "mentee_form_updated_at"
    t.text "mentor_description"
    t.datetime "mentor_form_updated_at"
    t.integer "monthly_dues", default: 0
    t.string "mostly_work_with"
    t.string "name"
    t.boolean "offering_mentorship"
    t.string "old_old_username"
    t.string "old_username"
    t.datetime "onboarding_package_form_submmitted_at"
    t.boolean "onboarding_package_fulfilled", default: false
    t.boolean "onboarding_package_requested", default: false
    t.boolean "onboarding_package_requested_again", default: false
    t.boolean "org_admin", default: false
    t.integer "organization_id"
    t.boolean "permit_adjacent_sponsors", default: true
    t.datetime "personal_data_updated_at"
    t.string "profile_image"
    t.integer "reactions_count", default: 0, null: false
    t.datetime "remember_created_at"
    t.string "remember_token"
    t.float "reputation_modifier", default: 1.0
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.text "resume_html"
    t.boolean "saw_onboarding", default: true
    t.integer "score", default: 0
    t.string "secret"
    t.boolean "seeking_mentorship"
    t.string "shipping_address"
    t.string "shipping_address_line_2"
    t.string "shipping_city"
    t.string "shipping_company"
    t.string "shipping_country"
    t.string "shipping_name"
    t.string "shipping_postal_code"
    t.string "shipping_state"
    t.boolean "shipping_validated", default: false
    t.datetime "shipping_validated_at"
    t.string "shirt_gender"
    t.string "shirt_size"
    t.integer "sign_in_count", default: 0, null: false
    t.string "signup_cta_variant"
    t.string "signup_refer_code"
    t.string "signup_referring_site"
    t.string "specialty"
    t.string "stackoverflow_url"
    t.string "stripe_id_code"
    t.text "summary"
    t.string "tabs_or_spaces"
    t.string "text_color_hex"
    t.string "text_only_name"
    t.string "top_languages"
    t.datetime "twitter_created_at"
    t.integer "twitter_followers_count"
    t.integer "twitter_following_count"
    t.string "twitter_username"
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.string "username"
    t.string "website_url"
    t.datetime "workshop_expiration"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["language_settings"], name: "index_users_on_language_settings", using: :gin
    t.index ["organization_id"], name: "index_users_on_organization_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "users_roles", id: false, force: :cascade do |t|
    t.integer "role_id"
    t.integer "user_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id"
  end

  add_foreign_key "badge_achievements", "badges"
  add_foreign_key "badge_achievements", "users"
  add_foreign_key "chat_channel_memberships", "chat_channels"
  add_foreign_key "chat_channel_memberships", "users"
  add_foreign_key "messages", "chat_channels"
  add_foreign_key "messages", "users"
  add_foreign_key "push_notification_subscriptions", "users"
end
