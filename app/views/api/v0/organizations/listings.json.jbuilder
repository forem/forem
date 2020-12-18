json.array! @listings do |listing|
  json.partial! "api/v0/shared/listing", listing: listing
  json.partial! "api/v0/shared/user", user: listing.user
  json.partial! "api/v0/shared/organization", organization: @organization
end
