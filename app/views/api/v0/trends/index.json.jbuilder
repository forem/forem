json.array! @trends do |trend|
  json.partial! "api/v0/shared/trend", trend: trend
end
