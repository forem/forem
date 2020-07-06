class CreateChatChannelInvitationLink < ApplicationService
  def initialize(chat_channel)
    @chat_channel = chat_channel
  end

  attr_accessor :chat_channel, :invitation_link

  def perform
    slug = "invitation-link-" + rand(100_000).to_s(26)
    url = "/chat_channel_memberships/join_channel_invitation/#{chat_channel.slug}?invitation_slug=#{slug}"
    expiry_time = DateTime.now + 1.day
    new_invitation_link = chat_channel.chat_channel_invitation_links.new(status: "active", url: url, expiry_time: expiry_time, slug: slug)
    new_invitation_link.save
    new_invitation_link
  end
end
