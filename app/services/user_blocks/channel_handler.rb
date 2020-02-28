module UserBlocks
  class ChannelHandler
    attr_reader :user_block

    def initialize(user_block)
      @user_block = user_block
    end

    def get_potential_chat_channel
      blocked_user = User.select(:id, :username).find(user_block.blocked_id)
      blocker = User.select(:id, :username).find(user_block.blocker_id)
      potential_slugs = ["#{blocked_user.username}/#{blocker.username}", "#{blocker.username}/#{blocked_user.username}"]
      blocker.chat_channels.where(slug: potential_slugs, channel_type: "direct").first
    end

    def block_chat_channel
      chat_channel = get_potential_chat_channel
      return if chat_channel.blank?

      chat_channel.update(status: "blocked")
      chat_channel.chat_channel_memberships.includes([:user]).each do |membership|
        membership.update(status: "left_channel")
      end
    end

    def unblock_chat_channel
      chat_channel = get_potential_chat_channel
      return if chat_channel.blank?

      chat_channel.update(status: "active")
      chat_channel.chat_channel_memberships.includes([:user]).each do |membership|
        membership.update(status: "active")
      end
    end
  end
end
