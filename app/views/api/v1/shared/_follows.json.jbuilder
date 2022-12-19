json.user_id       user.id
json.name          user.name
json.path          "/#{user.path.delete_prefix('/')}"
json.username      user.try(:username) || user.name
json.profile_image user.profile_image_url_for(length: 60)
