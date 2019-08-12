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

  user = article.user
  user_profile_image = ProfileImage.new(article.user)
  json.user do
    json.name             user.name
    json.username         user.username
    json.twitter_username user.twitter_username
    json.github_username  user.github_username
    json.website_url      user.processed_website_url
    json.profile_image    user_profile_image.get(640)
    json.profile_image_90 user_profile_image.get(90)
  end

  if article.organization
    organization = article.organization
    organization_profile_image = ProfileImage.new(article.organization)
    json.organization do
      json.name             organization.name
      json.username         organization.username
      json.slug             organization.slug
      json.profile_image    organization_profile_image.get(640)
      json.profile_image_90 organization_profile_image.get(90)
    end
  end

  flare_tag = FlareTag.new(article).tag
  if flare_tag
    json.flare_tag do
      json.name             flare_tag.name
      json.bg_color_hex     flare_tag.bg_color_hex
      json.text_color_hex   flare_tag.text_color_hex
    end
  end
end
