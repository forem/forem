json.success true
json.result do
  json.chat_channel do
    json.name @channel.channel_name
    json.type @channel.channel_type
    json.description @channel.description
    json.discoverable @channel.discoverable
    json.slug @channel.slug
    json.status @channel.status
    json.id @channel.id
  end

  json.memberships do
    json.active membership_users(@channel.active_memberships)
    json.pending membership_users(@channel.pending_memberships)
    json.requested membership_users(@channel.requested_memberships)
  end
  json.current_membership @membership
  json.invitation_link URL.url(@invitation_link)
end
