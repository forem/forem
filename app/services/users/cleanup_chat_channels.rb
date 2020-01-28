module Users
  module CleanupChatChannels
    def self.call(user)
      user.chat_channels.each do |chat_channel|
        chat_channel.remove_from_index!
        chat_channel.chat_channel_memberships.each do |ccm|
          ccm.remove_from_index!
          ccm.destroy!
        end

        # We only destroy direct message channels, not open and invite-only ones
        next unless chat_channel.direct?

        chat_channel.destroy!
      end
    end
  end
end
