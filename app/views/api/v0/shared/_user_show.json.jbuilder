json.type_of "user"

json.extract!(
  user,
  :id,
  :username,
  :name,
  :twitter_username,
  :github_username,
)

Profile.static_fields.each do |attr|
  json.set! attr, user.profile.public_send(attr)
end

json.joined_at     user.created_at.strftime("%b %e, %Y")
json.profile_image Images::Profile.call(user.profile_image_url, length: 320)
