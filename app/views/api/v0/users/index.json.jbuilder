json.array! @users.each do |user|
  json.id                     user.id
  json.name                   user.name
  json.username               user.username
  json.profile_image_url      ProfileImage.new(user).get(90)
  json.following              current_user ? current_user.following?(user) : false
end
