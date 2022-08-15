json.array! @readinglist do |reaction|
  json.type_of "readinglist"
  json.extract!(reaction, :id, :status)
  json.created_at utc_iso_timestamp(reaction.created_at)
  json.article do
    article = @articles_by_reaction_ids[reaction.id]
    json.partial! "api/v1/articles/article", article: article
    json.tags article.cached_tag_list
    json.partial! "api/v1/shared/user", user: @users_by_id[article.user_id]
    if article.organization
      json.partial! "api/v1/shared/organization", organization: article.organization
    end
  end
end
