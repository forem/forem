json.array! @articles do |article|
  json.extract!(
    article,
    :id,
    :title,
    :description,
    :published_at,
    :comments_count,
    :public_reactions_count,
  )

  json.tag_list article.cached_tag_list

  json.user do
    json.name              article.user.name
    json.profile_image_url article.user.profile_image_url_for(length: 90)
  end
end
