json.array! @follows do |follow|
  json.type_of    "user_follower"
  json.id         follow.id
  json.created_at utc_iso_timestamp(follow.created_at)

  json.partial! "api/v0/shared/follows", user: follow.follower
end
