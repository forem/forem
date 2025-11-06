# Core attributes that are always needed
article_attributes_to_include = %i[
  title path id user_id comments_count public_reactions_count organization_id
  reading_time video_thumbnail_url video edited_at
  experience_level_rating experience_level_rating_distribution main_image_height
  type_of subforem_id
]

# Core methods that are always needed
article_methods_to_include = %i[
  flare_tag class_name cloudinary_video_url published_at_int
  published_timestamp main_image_background_hex_color
  public_reaction_categories readable_publish_date video_duration_in_minutes
]

json.array!(@stories) do |article|
  # Build explicit cache key with all factors that affect the rendered article
  # Using explicit fields instead of updated_at because update_column bypasses timestamp updates
  cache_key = [
    "article",
    article.id,
    article.updated_at,
    article.edited_at,
    article.last_comment_at,
    article.public_reactions_count, # Changes when reactions are added/removed
    article.cached_user, # Text field containing serialized user data
    article.cached_organization, # Text field containing serialized organization data
    I18n.locale,
  ].join("-")
  
  # Only cache for pages 1-2 since those get the most traffic
  # Cache expires after 6 hours to ensure freshness
  json.cache_if! @page <= 2, cache_key, expires_in: 6.hours do
    json.extract! article, *article_attributes_to_include

    # Optimize user data - only call as_json once
    cached_user = article.cached_user.as_json
    cached_user[:cached_base_subscriber] = cached_user["cached_base_subscriber?"]
    json.user cached_user

    # Only include organization if it exists
    if article.cached_organization?
      json.organization article.cached_organization.as_json
    end

    json.pinned article.pinned?

    # Optimize main_image - avoid cloud_cover_url call when not needed
    json.main_image article.main_image? ? cloud_cover_url(article.main_image, article.subforem_id) : nil

    json.url URL.article(article)
    json.tag_list article.cached_tag_list_array

    # Only include body_preview for status articles
    if article.type_of == "status"
      json.body_preview article.body_preview
      # Only include special title methods for status articles
      json.title_finalized_for_feed article.title_finalized_for_feed
      json.title_for_metadata article.title_for_metadata
    end

    json.extract! article, *article_methods_to_include

    # Only load top_comments if the article has comments - major N+1 optimization
    if article.comments_count > 0
      # Use the preloaded comments to avoid additional queries
      comments = article.public_send(@comments_variant.to_sym).first(3)
      json.top_comments comments do |comment|
        comment = comment.decorate
        json.comment_id comment.id
        json.extract! comment, :user_id, :published_timestamp, :published_at_int, :safe_processed_html, :path
        # User data should already be preloaded via includes
        json.extract! comment.user, :username, :name, :profile_image_90
      end
    else
      json.top_comments []
    end

    # Use cached subforem logo to avoid repeated Settings::General calls
    # Handle both single subforem and root subforem scenarios
    if @cached_subforem_logo
      # Single subforem - use cached value
      json.subforem_logo @cached_subforem_logo
    elsif @cached_subforem_logos
      # Root subforem - cache per subforem_id to avoid repeated queries
      json.subforem_logo @cached_subforem_logos[article.subforem_id] ||= Settings::General.logo_png(subforem_id: article.subforem_id)
    else
      # Fallback - direct call (should rarely happen)
      json.subforem_logo Settings::General.logo_png(subforem_id: article.subforem_id)
    end

    # Only load context_note if it exists (rarely used)
    json.context_note article.context_notes.first&.processed_html
  end
  
  # These fields are added outside the cache so they don't fragment the cache
  json.current_user_signed_in user_signed_in?
  json.feed_config @feed_config&.id
end
