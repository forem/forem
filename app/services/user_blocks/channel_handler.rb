module UserBlocks
  class ChannelHandler
    attr_reader :user_block

    def initialize(user_block)
      @user_block = user_block
    end

    def get_potential_chat_channel
      blocked_user = User.select(:id, :username).find(user_block.blocked_id)
      blocker = User.select(:id).find(user_block.blocker_id)
      blocker.chat_channels.find_by("slug LIKE ? AND channel_type = ?", "%#{blocked_user.username}%", "direct")
    end

    def block_chat_channel
      chat_channel = get_potential_chat_channel
      return if chat_channel.blank?

      chat_channel.update(status: "blocked")
      chat_channel.chat_channel_memberships.each do |membership|
        membership.update(status: "left_channel")
        membership.remove_from_index!
      end
    end

    def unblock_chat_channel
      chat_channel = get_potential_chat_channel
      return if chat_channel.blank?

      chat_channel.update(status: "active")
      chat_channel.chat_channel_memberships.each do |membership|
        membership.update(status: "active")
        membership.index!
      end
    end
  end
end
