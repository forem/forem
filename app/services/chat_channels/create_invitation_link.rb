module ChatChannels
  class CreateInvitationLink
    def initialize(chat_channel)
      @chat_channel = chat_channel
    end

    def self.call(*args)
      new(*args).call
    end

    attr_accessor :chat_channel

    def call
      slug = "invitation-link-#{SecureRandom.hex(3)}"
      path = "/chat_channel_memberships/join_channel_invitation/#{chat_channel.slug}?invitation_slug=#{slug}"
      expiry_at = 1.day.from_now
      invitation_link = chat_channel.invitation_links.new(status: "active", path: path, expiry_at: expiry_at, slug: slug)
      invitation_link.save
      invitation_link
    end
  end
end
