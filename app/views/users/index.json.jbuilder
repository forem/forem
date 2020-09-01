json.array! @users.each do |user|
  json.extract!(user, :id, :name, :username)

  json.summary           truncate(user.summary.presence || "Active #{community_name} author", length: 100)
  json.profile_image_url Images::Profile.call(user.profile_image_url, length: 90)
  json.following         false
end
