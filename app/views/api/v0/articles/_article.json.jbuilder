json.type_of "article"

json.extract!(
  article,
  :id,
  :title,
  :description,
  :readable_publish_date,
  :slug,
  :path,
  :url,
  :comments_count,
  :public_reactions_count,
  :collection_id,
  :published_timestamp,
)

json.positive_reactions_count article.public_reactions_count
json.cover_image     cloud_cover_url(article.main_image)
json.social_image    article_social_image_url(article)
json.canonical_url   article.processed_canonical_url
json.created_at      utc_iso_timestamp(article.created_at)
json.edited_at       utc_iso_timestamp(article.edited_at)
json.crossposted_at  utc_iso_timestamp(article.crossposted_at)
json.published_at    utc_iso_timestamp(article.published_at)
json.last_comment_at utc_iso_timestamp(article.last_comment_at)
json.reading_time_minutes article.reading_time
