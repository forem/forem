class ChatChannel < ApplicationRecord
  attr_accessor :current_user, :usernames_string

  has_many :messages, dependent: :destroy
  has_many :chat_channel_memberships, dependent: :destroy
  has_many :users, through: :chat_channel_memberships

  has_many :active_memberships, -> { where status: "active" }, class_name: "ChatChannelMembership", inverse_of: :chat_channel
  has_many :pending_memberships, -> { where status: "pending" }, class_name: "ChatChannelMembership", inverse_of: :chat_channel
  has_many :rejected_memberships, -> { where status: "rejected" }, class_name: "ChatChannelMembership", inverse_of: :chat_channel
  has_many :mod_memberships, -> { where role: "mod" }, class_name: "ChatChannelMembership", inverse_of: :chat_channel
  has_many :active_users, through: :active_memberships, class_name: "User", source: :user
  has_many :pending_users, through: :pending_memberships, class_name: "User", source: :user
  has_many :rejected_users, through: :rejected_memberships, class_name: "User", source: :user
  has_many :mod_users, through: :mod_memberships, class_name: "User", source: :user

  validates :channel_type, presence: true, inclusion: { in: %w[open invite_only direct] }
  validates :status, presence: true, inclusion: { in: %w[active inactive blocked] }
  validates :slug, uniqueness: true, presence: true
  validates :description, length: { maximum: 200 }, allow_blank: true

  def open?
    channel_type == "open"
  end

  def direct?
    channel_type == "direct"
  end

  def invite_only?
    channel_type == "invite_only"
  end

  def group?
    channel_type != "direct"
  end

  def clear_channel
    messages.destroy_all
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

  class << self
    def create_with_users(users:, channel_type: "direct", contrived_name: "New Channel", membership_role: "member")
      raise "Invalid direct channel" if users.size != 2 && channel_type == "direct"

      usernames = users.map(&:username).sort
      slug = channel_type == "direct" ? usernames.join("/") : contrived_name.to_s.parameterize + "-" + rand(100_000).to_s(26)
      contrived_name = "Direct chat between " + usernames.join(" and ") if channel_type == "direct"
      channel = find_or_create_chat_channel(channel_type, slug, contrived_name)
      if channel_type == "direct"
        channel.add_users(users)
      else
        channel.invite_users(users: users, membership_role: membership_role)
      end
      channel
    end

    private

    def find_or_create_chat_channel(channel_type, slug, contrived_name)
      channel = ChatChannel.find_by(slug: slug)
      if channel
        raise "Blocked channel" if channel.status == "blocked"

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
      end
      channel
    end
  end

  def add_users(users)
    Array(users).each do |user|
      ChatChannelMembership.find_or_create_by!(user_id: user.id, chat_channel_id: id)
    end
  end

  def invite_users(users:, membership_role: "member", inviter: nil)
    invitation_sent = 0
    Array(users).each do |user|
      existing_membership = ChatChannelMembership.find_by(user_id: user.id, chat_channel_id: id)
      if existing_membership.present? && %w[active pending].exclude?(existing_membership.status)
        if existing_membership.update(status: "pending", role: membership_role)
          NotifyMailer.channel_invite_email(existing_membership, inviter).deliver_later
          invitation_sent += 1
        end
      else
        membership = ChatChannelMembership.create(user_id: user.id, chat_channel_id: id, role: membership_role, status: "pending")
        if membership.persisted?
          NotifyMailer.channel_invite_email(membership, inviter).deliver_later
          invitation_sent += 1
        end
      end
    end
    invitation_sent
  end

  def remove_user(user)
    chat_channel_memberships.where(user: user).destroy_all
  end

  def pusher_channels
    if invite_only?
      "presence-channel-#{id}"
    elsif open?
      "open-channel-#{id}"
    else
      chat_channel_memberships.pluck(:user_id).map { |id| "private-message-notifications-#{id}" }
    end
  end

  def channel_users_ids
    chat_channel_memberships.pluck(:user_id)
  end

  def adjusted_slug(user = nil, caller_type = "receiver")
    user ||= current_user
    if direct? && caller_type == "receiver"
      "@" + slug.gsub("/#{user.username}", "").gsub("#{user.username}/", "")
    elsif caller_type == "sender"
      "@" + user.username
    else
      slug
    end
  end

  def channel_human_names
    active_memberships.
      order("last_opened_at DESC").limit(5).includes(:user).map do |membership|
        membership.user.name
      end
  end

  def channel_users
    obj = {}

    relation = active_memberships.includes(:user).select(:id, :user_id, :last_opened_at)

    relation.order(last_opened_at: :desc).each do |membership|
      obj[membership.user.username] = user_obj(membership)
    end

    obj
  end

  def channel_mod_ids
    mod_users.pluck(:id)
  end

  def pending_users_select_fields
    pending_users.select(:id, :username, :name, :updated_at)
  end

  private

  def user_obj(membership)
    {
      profile_image: ProfileImage.new(membership.user).get(width: 90),
      darker_color: membership.user.decorate.darker_color,
      name: membership.user.name,
      last_opened_at: membership.last_opened_at,
      username: membership.user.username,
      id: membership.user_id
    }
  end
end
