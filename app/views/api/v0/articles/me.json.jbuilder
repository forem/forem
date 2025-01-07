json.array! @articles do |article|
  json.type_of "article"

  json.extract!(
    article,
    :id, :title, :description, :published, :published_at,
    :slug, :path, :url, :comments_count, :public_reactions_count, :page_views_count,
    :published_timestamp, :body_markdown
  )

  json.positive_reactions_count article.public_reactions_count
  json.cover_image              cloud_cover_url(article.main_image)
  json.tag_list                 article.cached_tag_list_array
  json.canonical_url            article.processed_canonical_url
  json.reading_time_minutes     article.reading_time

  json.partial! "api/v0/shared/user", user: article.user

  if article.organization
    json.partial! "api/v0/shared/organization", organization: article.organization
  end

  flare_tag = FlareTag.new(article).tag
  if flare_tag
    json.partial! "flare_tag", flare_tag: flare_tag
  end
end
