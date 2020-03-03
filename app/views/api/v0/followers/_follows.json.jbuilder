json.array! follows do |follow|
  json.type_of  type_of
  json.id       follow.id
  json.partial! "api/v0/shared/follows", user: follow.follower
end
