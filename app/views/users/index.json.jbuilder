json.array! @users.each do |user|
  json.extract!(user, :id, :name, :username)

  json.summary           truncate(user.summary.presence || "Active #{community_name} author", length: 100)
  json.profile_image_url ProfileImage.new(user).get(width: 90)
  json.following         false
end
