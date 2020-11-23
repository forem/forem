json.array! @video_articles do |video_article|
  json.type_of "video_article"

  json.extract!(
    video_article,
    :id,
    :path,
    :cloudinary_video_url,
    :title,
    :user_id,
    :video_duration_in_minutes,
    :video_source_url,
  )

  json.user do
    json.name video_article.user.name
  end
end
