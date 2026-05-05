json.id user.id
json.username user.username
json.name user.name
json.email user.email
json.registered_at user.registered_at
json.status user_moderation_status(user)
json.profile do
  profile = user.profile
  json.summary profile&.summary
  json.location profile&.location
  json.website_url profile&.website_url
end
json.identities user.identities do |identity|
  json.partial!("api/v1/admin/user_identities/identity", identity: identity)
end
json.counts do
  json.articles user.articles_count
  json.comments user.comments_count
  json.reactions user.reactions_count
end
