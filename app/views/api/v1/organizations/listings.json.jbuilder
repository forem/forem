json.array! @listings do |listing|
  json.partial! "api/v1/shared/listing", listing: listing
  json.partial! "api/v1/shared/user", user: listing.user
  json.partial! "api/v1/shared/organization", organization: @organization
end
