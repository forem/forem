json.array! @follows do |follow|
  json.type_of                 "organization_follower"
  json.id                      follow.id
  json.organization_id         follow.followable_id
  json.partial! "api/v0/shared/follows", user: follow.follower
end
