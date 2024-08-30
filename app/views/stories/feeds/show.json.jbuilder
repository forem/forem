article_attributes_to_include = %i[
  title path id user_id comments_count public_reactions_count organization_id
  reading_time video_thumbnail_url video video_duration_in_minutes
  experience_level_rating experience_level_rating_distribution main_image_height
]
article_methods_to_include = %i[
  readable_publish_date flare_tag class_name
  cloudinary_video_url video_duration_in_minutes published_at_int
  published_timestamp main_image_background_hex_color
  public_reaction_categories
]

json.array!(@stories) do |article|
  json.extract! article, *article_attributes_to_include
  # Make both cached_user_subscriber and cached_user_subscriber? valid
  cached_user = article.cached_user.as_json
  cached_user[:cached_base_subscriber] = cached_user["cached_base_subscriber?"]
  json.user cached_user

  if article.cached_organization?
    json.organization article.cached_organization.as_json
  end

  json.pinned article.pinned?

  if article.main_image?
    json.main_image cloud_cover_url(article.main_image)
  else
    json.main_image nil
  end

  json.tag_list article.cached_tag_list_array
  json.extract! article, *article_methods_to_include

  json.top_comments article.public_send(@comments_variant.to_sym) do |comment|
    comment = comment.decorate
    json.comment_id comment.id
    json.extract! comment, :user_id, :published_timestamp, :published_at_int, :safe_processed_html, :path
    json.extract! comment.user, :username, :name, :profile_image_90
  end
end
