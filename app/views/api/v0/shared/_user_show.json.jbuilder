json.type_of "user"

json.extract!(
  user,
  :id,
  :username,
  :name,
  :summary,
  :twitter_username,
  :github_username,
  :website_url,
  :location,
)

json.joined_at     user.created_at.strftime("%b %e, %Y")
json.profile_image Images::Profile.call(user.profile_image_url, length: 320)
