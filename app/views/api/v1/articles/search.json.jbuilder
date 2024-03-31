json.array! @articles do |article|
  json.partial! "api/v1/articles/article", article: article

  json.body_markdown article.body_markdown if article.respond_to?(:body_markdown)

  # /api/articles and /api/articles/:id have opposite representations
  # of `tag_list` and `tags and we can't align them without breaking the API,
  # this is fully documented in the API docs
  # see <https://github.com/forem/forem/issues/4206> for more details
  json.tag_list article.cached_tag_list_array
  json.tags article.cached_tag_list

  json.partial! "api/v1/shared/user", user: article.user

  if article.organization
    json.partial! "api/v1/shared/organization", organization: article.organization
  end

  flare_tag = FlareTag.new(article).tag
  if flare_tag
    json.partial! "api/v1/articles/flare_tag", flare_tag: flare_tag
  end
end
