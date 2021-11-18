module Users
  module CleanupChatChannels
    def self.call(user)
      # We only destroy direct message channels, not open and invite-only ones
      direct_channels = user.chat_channels.where(channel_type: "direct")
      direct_channels.each(&:destroy!)

      # Clean up the banished user's remaining channel memberships
      user.reload.chat_channel_memberships.each(&:destroy!)
    end
  end
end
