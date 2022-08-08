json.partial! "api/v1/shared/listing", listing: @listing

json.partial! "api/v1/shared/user", user: @listing.user

if @listing.organization
  json.partial! "api/v1/shared/organization", organization: @listing.organization
end
