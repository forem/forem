json.success true
json.result do
  json.channel_joining_memberships formatted_membership_user(@memberships)
  json.user_joining_requests @user_invitations ? formatted_membership_user(@user_invitations) : []
end
