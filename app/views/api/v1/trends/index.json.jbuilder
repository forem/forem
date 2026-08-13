json.array! @trends do |trend|
  json.partial! "api/v1/shared/trend", trend: trend
end
