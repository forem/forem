json.array! @users.each do |user|
  json.id                     user.id
  json.name                   user.name
  json.username               user.username
  json.profile_image_url      ProfileImage.new(user).get(90)
  json.following              false
end
