article_attributes_to_include = %i[
  title path id user_id comments_count public_reactions_count organization_id
  reading_time video_thumbnail_url video video_duration_in_minutes
  experience_level_rating experience_level_rating_distribution
]
article_methods_to_include = %i[
  readable_publish_date flare_tag class_name
  cloudinary_video_url video_duration_in_minutes published_at_int
  published_timestamp
]

json.array!(@stories) do |article|
  json.extract! article, *article_attributes_to_include
  json.user article.cached_user.as_json

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

  json.top_comments article.top_comments do |comment|
    comment = comment.decorate
    json.comment_id comment.id
    json.extract! comment, :user_id, :published_timestamp, :published_at_int, :safe_processed_html, :path
    json.extract! comment.user, :username, :name, :profile_image_90
  end
end
