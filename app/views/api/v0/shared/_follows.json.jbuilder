json.name                    user.name
json.path                    user.path
json.username                user.try(:username) || user.name
json.profile_image           ProfileImage.new(user).get(60)
