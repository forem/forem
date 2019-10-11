json.array! @followed_podcasts do |follow|
  json.type_of                 "following"
  json.id                      follow.id
  json.name                    follow.followable.name
  json.path                    follow.followable.path
  json.username                follow.followable.name
  json.profile_image           follow.followable.image_url
end
