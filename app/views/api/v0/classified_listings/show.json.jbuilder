json.partial! "listing", listing: @classified_listing

json.partial! "api/v0/shared/user", user: @classified_listing.user

if @classified_listing.organization
  json.partial! "api/v0/shared/organization", organization: @classified_listing.organization
end
