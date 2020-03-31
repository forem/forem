json.array! @users.each do |user|
  json.id                     user.id
  json.name                   user.name
  json.username               user.username
  json.summary                truncate(user.summary.presence || "Active DEV author", length: 100)
  json.profile_image_url      ProfileImage.new(user).get(width: 90)
  json.following              false
end
