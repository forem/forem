user_profile_image = ProfileImage.new(user)

json.user do
  json.extract!(user, :name, :username, :twitter_username, :github_username)

  json.website_url      user.processed_website_url
  json.profile_image    user_profile_image.get(width: 640)
  json.profile_image_90 user_profile_image.get(width: 90)
end
