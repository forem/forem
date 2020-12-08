json.array! @listings do |listing|
  json.partial! "api/v0/listings/listing", listing: listing
end
