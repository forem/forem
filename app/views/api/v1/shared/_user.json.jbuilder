json.user do
  json.extract!(user, :name, :username, :twitter_username, :github_username)

  json.user_id          user.id
  json.website_url      user.processed_website_url
  json.profile_image    user.profile_image_url_for(length: 640)
  json.profile_image_90 user.profile_image_url_for(length: 90)
end
