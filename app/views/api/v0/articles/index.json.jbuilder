json.array! @articles do |article|
  json.type_of            "article"
  json.id                 article.id
  json.title              article.title
  json.description        article.description
  json.cover_image        cloud_cover_url(article.main_image)
  json.published_at       article.published_at
  json.tag_list           article.cached_tag_list_array
  json.slug               article.slug
  json.path               article.path
  json.url                article.url
  json.canonical_url      article.processed_canonical_url
  json.comments_count     article.comments_count
  json.positive_reactions_count article.positive_reactions_count
  json.published_timestamp article.published_timestamp

  json.partial! "api/v0/shared/user", user: article.user

  if article.organization
    json.partial! "api/v0/shared/organization", organization: article.organization
  end

  flare_tag = FlareTag.new(article).tag
  if flare_tag
    json.partial! "flare_tag", flare_tag: flare_tag
  end
end
