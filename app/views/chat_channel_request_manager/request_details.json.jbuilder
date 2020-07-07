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
  if @membership.role == "mod"
    json.memberships do
      json.pending formatted_membership_user(@channel.pending_memberships)
      json.requested formatted_membership_user(@channel.requested_memberships)
    end
  end
  json.user_joining_requests @user_joining_requests ? formatted_membership_user(@user_joining_requests) : []
  json.current_membership @membership
end
