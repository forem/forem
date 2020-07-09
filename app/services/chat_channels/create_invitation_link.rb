module ChatChannels
  module CreateInvitationLink
    module_function

    def call(chat_channel)
      invitation_slug = "invitation-link-#{SecureRandom.hex(3)}"
      chat_channel.update(invitation_slug: invitation_slug)
      unless chat_channel.errors.any?
        path = "/join_channel_invitation/#{chat_channel.slug}?invitation_slug=#{invitation_slug}"
        Rails.cache.write(invitation_slug, path, expires_in: 12.hours)
      end
      chat_channel
    end
  end
end
