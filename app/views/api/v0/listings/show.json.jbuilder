json.partial! "api/v0/shared/listing", listing: @listing

json.partial! "api/v0/shared/user", user: @listing.user

if @listing.organization
  json.partial! "api/v0/shared/organization", organization: @listing.organization
end
