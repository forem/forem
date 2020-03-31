json.name                    user.name
json.path                    "/" + user.path.delete_prefix("/")
json.username                user.try(:username) || user.name
json.profile_image           ProfileImage.new(user).get(width: 60)
