json.array! @webhooks.each do |endpoint|
  json.id             endpoint.id
  json.target_url     endpoint.target_url
  json.events         endpoint.events
  json.source         endpoint.source
  json.created_at     endpoint.created_at.strftime("%H:%M  %b %e, %Y")
  json.updated_at     endpoint.updated_at.strftime("%H:%M %b %e, %Y")
end
