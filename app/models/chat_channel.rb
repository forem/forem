class ChatChannel < ApplicationRecord
  include AlgoliaSearch
  attr_accessor :current_user

  has_many :messages
  has_many :chat_channel_memberships
  has_many :users, through: :chat_channel_memberships

  validates :channel_type, presence: true, inclusion: { in: %w(open invite_only direct) }
  validates :status, presence: true, inclusion: { in: %w(active inactive) }
  validates :slug, uniqueness: true, presence: true

  algoliasearch index_name: "SecuredChatChannel_#{Rails.env}" do
    attribute :id, :viewable_by, :slug, :channel_type,
      :channel_name, :channel_users, :last_message_at, :status,
      :messages_count, :channel_human_names
    searchableAttributes [:channel_name, :channel_slug, :channel_human_names]
    attributesForFaceting ["filterOnly(viewable_by)","filterOnly(status)"]
    ranking ["desc(last_message_at)"]
  end

  def clear_channel
    messages.each(&:destroy!)
    Pusher.trigger(pusher_channels, "channel-cleared", { chat_channel_id: id }.to_json)
    true
  rescue Pusher::Error => e
    logger.info "PUSHER ERROR: #{e.message}"
  end

  def has_member?(user)
    users.include?(user)
  end

  def last_opened_at(user = nil)
    user ||= current_user
    chat_channel_memberships.where(user_id: user.id).pluck(:last_opened_at).first
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

    if channel = ChatChannel.find_by_slug(slug)
      channel.status = "active"
      channel.save
    else
      channel = create(
        channel_type: channel_type,
        channel_name: contrived_name,
        slug: slug,
        last_message_at: 1.week.ago,
        status: "active",
      )
      channel.add_users(users)
      channel.index!
    end
    channel
  end

  def add_users(users)
    Array(users).each do |user|
      ChatChannelMembership.create!(user_id: user.id, chat_channel_id: id)
    end
  end

  def pusher_channels
    if channel_type == "invite_only"
      "presence-channel-#{id}"
    elsif channel_type == "open"
      "open-channel-#{id}"
    else
      chat_channel_memberships.pluck(:user_id).map { |id| "private-message-notifications-#{id}"}
    end
  end


  def adjusted_slug(user = nil, caller_type="reciever")
    user ||= current_user
    if channel_type == "direct" && caller_type == "reciever"
      "@"+slug.gsub("/#{user.username}","").gsub("#{user.username}/","")
    elsif caller_type == "sender"
      "@"+user.username
    else
      slug
    end
  end

  def viewable_by
    chat_channel_memberships.pluck(:user_id)
  end

  def messages_count
    messages.size
  end

  def channel_human_names
    chat_channel_memberships.
      order("last_opened_at DESC").limit(20).includes(:user).map do |m|
        m.user.name
      end
  end

  def channel_users
    pics_obj = {}
    chat_channel_memberships.
      order("last_opened_at DESC").limit(5).includes(:user).each do |m|
      pics_obj[m.user.username] = {
        profile_image: ProfileImage.new(m.user).get(90),
        darker_color: m.user.decorate.darker_color,
        name: m.user.name,
        last_opened_at: m.last_opened_at,
        username: m.user.username,
      }
    end
    pics_obj
  end
end
