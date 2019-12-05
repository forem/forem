json.array! @follows do |follow|
  json.type_of                 "user_following"
  json.id                      follow.id
  json.partial! "api/v0/shared/follows", user: follow.followable
end
