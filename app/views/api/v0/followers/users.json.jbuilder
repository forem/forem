json.array! @follows do |follow|
  json.type_of "user_follower"
  json.id      follow.id

  json.partial! "api/v0/shared/follows", user: follow.follower
end
