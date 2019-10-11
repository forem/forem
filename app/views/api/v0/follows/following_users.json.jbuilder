json.array! @follows do |follow|
  json.type_of                 "following"
  json.id                      follow.id
  json.name                    follow.followable.name
  json.path                    follow.followable.path
  json.username                follow.followable.username
  json.profile_image           ProfileImage.new(follow.followable).get(60)
end
