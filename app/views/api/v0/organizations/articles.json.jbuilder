json.array! @articles do |article|
  json.partial! "api/v0/shared/article", article: article

  json.tag_list article.cached_tag_list_array
  json.tags article.cached_tag_list

  json.partial! "api/v0/shared/user", user: article.user
  json.partial! "api/v0/shared/organization", organization: @organization

  flare_tag = FlareTag.new(article).tag
  if flare_tag
    json.partial! "api/v0/shared/flare_tag", flare_tag: flare_tag
  end
end
