json.array! @follows do |follow|
  json.type_of                 "follower"
  json.id                      follow.follower.id
  json.name                    follow.follower.name
  json.path                    follow.follower.path
  json.username                follow.follower.username
  json.profile_image           ProfileImage.new(follow.follower).get(60)
end
