json.array! @users do |user|
  json.type_of "org_user"
  json.extract!(user, :name, :username, :twitter_username, :github_username)

  json.website_url user.processed_website_url
  json.profile_image Images::Profile.call(user.profile_image_url, length: 320)
end
