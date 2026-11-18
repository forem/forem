json.array! @reactions do |reaction|
  json.article_id reaction.reactable_id
  json.extract! reaction, :category, :created_at

  json.user do
    json.user_id reaction.user.id
    json.extract! reaction.user, :username, :name, :github_username, :twitter_username
  end
end
