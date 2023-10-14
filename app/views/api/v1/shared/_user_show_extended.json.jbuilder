json.type_of "user"

json.extract!(
  user,
  :id,
  :username,
  :name,
  :twitter_username,
  :github_username,
)

json.email user.setting.display_email_on_profile ? user.email : nil

Profile.static_fields.each do |attr|
  json.set! attr, user.profile.public_send(attr)
end

json.joined_at     I18n.l(user.created_at, format: :json)
json.profile_image user.profile_image_url_for(length: 320)
