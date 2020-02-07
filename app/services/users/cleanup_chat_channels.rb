module Users
  module CleanupChatChannels
    def self.call(user)
      # We only destroy direct message channels, not open and invite-only ones
      direct_channels = user.chat_channels.where(channel_type: "direct")
      direct_channels.each do |direct_channel|
        cleanup_memberships(direct_channel.chat_channel_memberships)
        direct_channel.destroy!
      end

      # Clean up the banished user's remaining channel memberships
      cleanup_memberships(user.chat_channel_memberships)
    end

    def self.cleanup_memberships(chat_channel_memberships)
      chat_channel_memberships.each do |ccm|
        ccm.remove_from_index!
        ccm.destroy!
      end
    end
    private_class_method :cleanup_memberships
  end
end
