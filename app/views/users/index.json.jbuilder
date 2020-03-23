json.array! @users.each do |user|
  json.id                     user.id
  json.name                   user.name
  json.username               user.username
  json.summary                user.summary.mb_chars.limit(100).to_s || "Active DEV author"
  json.profile_image_url      ProfileImage.new(user).get(width: 90)
  json.following              false
end
