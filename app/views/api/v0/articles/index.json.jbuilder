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

  json.user do
    json.name             article.user.name
    json.username         article.user.username
    json.twitter_username article.user.twitter_username
    json.github_username  article.user.github_username
    json.website_url      article.user.processed_website_url
    json.profile_image    ProfileImage.new(article.user).get(640)
    json.profile_image_90 ProfileImage.new(article.user).get(90)
  end

  if article.organization
    json.organization do
      json.name             article.organization.name
      json.username         article.organization.username
      json.slug             article.organization.slug
      json.profile_image    ProfileImage.new(article.organization).get(640)
      json.profile_image_90 ProfileImage.new(article.organization).get(90)
    end
  end

  if FlareTag.new(article).tag
    json.flare_tag do
      json.name             FlareTag.new(article).tag.name
      json.bg_color_hex     FlareTag.new(article).tag.bg_color_hex
      json.text_color_hex   FlareTag.new(article).tag.text_color_hex
    end
  end
end
