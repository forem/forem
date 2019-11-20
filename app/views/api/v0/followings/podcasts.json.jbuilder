json.array! @followed_podcasts do |follow|
  json.type_of                 "podcast_following"
  json.id                      follow.id
  json.partial! "api/v0/shared/follows", user: follow.followable
end
