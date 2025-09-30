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
  public_reaction_categories title_finalized title_finalized_for_feed
  title_for_metadata readable_publish_date video_duration_in_minutes
]

json.array!(@stories) do |article|
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

  # Only include body_preview for status articles using optimized method
  if article.type_of == "status"
    json.body_preview article.body_preview_for_status
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
  json.subforem_logo @cached_subforem_logo || Settings::General.logo_png(subforem_id: article.subforem_id)

  # Only load context_note if it exists (rarely used)
  json.context_note article.context_notes.first&.processed_html

  json.current_user_signed_in user_signed_in?
  json.feed_config @feed_config&.id
end
