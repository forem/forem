json.array! @articles do |article|
  json.partial! "api/v0/articles/article", article: article

  # /api/articles and /api/articles/:id have opposite representations
  # of `tag_list` and `tags and we can't align them without breaking the API,
  # this is fully documented in the API docs
  # see <https://github.com/thepracticaldev/dev.to/issues/4206> for more details
  json.tag_list article.cached_tag_list_array
  json.tags article.cached_tag_list

  json.partial! "api/v0/shared/user", user: article.user

  if article.organization
    json.partial! "api/v0/shared/organization", organization: article.organization
  end

  flare_tag = FlareTag.new(article).tag
  if flare_tag
    json.partial! "api/v0/articles/flare_tag", flare_tag: flare_tag
  end
end
