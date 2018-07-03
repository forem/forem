class ChatChannel < ApplicationRecord
  include AlgoliaSearch
  attr_accessor :current_user

  has_many :messages
  has_many :chat_channel_memberships
  has_many :users, through: :chat_channel_memberships
  
  has_many :active_memberships, -> { where status: "active" }, class_name: 'ChatChannelMembership'
  has_many :pending_memberships, -> { where status: "pending" }, class_name: 'ChatChannelMembership'
  has_many :rejected_memberships, -> { where status: "rejected" }, class_name: 'ChatChannelMembership'
  has_many :mod_memberships, -> { where role: "mod" }, class_name: 'ChatChannelMembership'
  has_many :active_users, :through => :active_memberships, class_name: "User", :source => :user
  has_many :pending_users, :through => :pending_memberships, class_name: "User", :source => :user
  has_many :rejected_users, :through => :rejected_memberships, class_name: "User", :source => :user
  has_many :mod_users, :through => :mod_memberships, class_name: "User", :source => :user

  validates :channel_type, presence: true, inclusion: { in: %w(open invite_only direct) }
  validates :status, presence: true, inclusion: { in: %w(active inactive) }
  validates :slug, uniqueness: true, presence: true

  algoliasearch index_name: "SecuredChatChannel_#{Rails.env}" do
    attribute :id, :viewable_by, :slug, :channel_type,
      :channel_name, :channel_users, :last_message_at, :status,
      :messages_count, :channel_human_names, :channel_mod_ids, :pending_usernames
    searchableAttributes [:channel_name, :channel_slug, :channel_human_names]
    attributesForFaceting ["filterOnly(viewable_by)", "filterOnly(status)", "filterOnly(channel_type)"]
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
    active_users.include?(user)
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
    active_memberships.pluck(:user_id)
  end

  def messages_count
    messages.size
  end

  def channel_human_names
    active_memberships.
      order("last_opened_at DESC").limit(5).includes(:user).map do |m|
        m.user.name
      end
  end

  def channel_users
    # Purely for algolia indexing
    obj = {}
    active_memberships.
      order("last_opened_at DESC").limit(80).includes(:user).each_with_index do |m, i|
      obj[m.user.username] = user_obj(m, i)
    end
    obj
  end

  def pending_usernames
    pending_users.pluck(:username)
  end

  def channel_mod_ids
    mod_users.pluck(:id)
  end

  def user_obj(m, i)
    {
      profile_image: i < 11 ? ProfileImage.new(m.user).get(90) : nil,
      darker_color: m.user.decorate.darker_color,
      name: m.user.name,
      last_opened_at: m.last_opened_at,
      username: m.user.username,
      id: m.user_id,
    }
  end
end
