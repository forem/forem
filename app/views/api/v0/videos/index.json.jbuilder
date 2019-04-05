json.array! @video_articles do |video_article|
  json.type_of                   "video_article"
  json.id                        video_article.id
  json.path                      video_article.path
  json.cloudinary_video_url      video_article.cloudinary_video_url
  json.title                     video_article.title
  json.user_id                   video_article.user_id
  json.video_duration_in_minutes video_article.video_duration_in_minutes

  json.user do
    json.name video_article.user.name
  end
end
