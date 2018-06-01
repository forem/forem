class ChatChannel < ApplicationRecord
  has_many :messages
  has_many :chat_channel_memberships
  has_many :users, through: :chat_channel_memberships

  validates :channel_type, presence: true, inclusion: { in: %w(open invite_only direct) }
  validates :slug, uniqueness: true, presence: true

  def clear_channel
    messages.each(&:destroy!)
    Pusher.trigger(id, "channel-cleared", { chat_channel_id: id }.to_json)
    true
  rescue Pusher::Error => e
    logger.info "PUSHER ERROR: #{e.message}"
  end

  def has_member?(user)
    users.include?(user)
  end

  def self.create_with_users(users, channel_type = "direct", contrived_name = "New Channel")
    raise "Invalid direct channel" if users.size != 2 && channel_type == "direct"
    if channel_type == "direct"
      usernames = users.map(&:username).sort
      contrived_name = "Direct chat between " + usernames.join(" and ")
      slug = usernames.join("/")
    else
      slug = contrived_name.to_s.downcase.tr(" ", "-").gsub(/[^\w-]/, "").tr("_", "") + "-" + rand(100000).to_s(26)
    end
    channel = create(channel_type: channel_type, channel_name: contrived_name, slug: slug)
    channel.add_users(users)
    channel
  end

  def add_users(users)
    Array(users).each do |user|
      ChatChannelMembership.create!(user_id: user.id, chat_channel_id: id)
    end
  end
end
