json.array! @articles do |article|
  json.id                         article.id
  json.title                      article.title
  json.description                article.description
  json.published_at               article.published_at
  json.tag_list                   article.cached_tag_list
  json.comments_count             article.comments_count
  json.positive_reactions_count   article.positive_reactions_count

  json.user do
    json.name                     article.user.name
    json.profile_image_url        ProfileImage.new(article.user).get(width: 90)
  end
end
