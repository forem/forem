json.user do
  json.extract!(user, :name, :username, :twitter_username, :github_username)

  json.website_url      user.processed_website_url
  json.profile_image    Images::Profile.call(user.profile_image_url, length: 640)
  json.profile_image_90 Images::Profile.call(user.profile_image_url, length: 90)
end
