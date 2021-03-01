class ChatChannel < ApplicationRecord
  attr_accessor :current_user, :usernames_string, :username_string

  resourcify

  CHANNEL_TYPES = %w[open invite_only direct].freeze
  STATUSES = %w[active inactive blocked].freeze

  has_many :messages, dependent: :destroy
  has_many :chat_channel_memberships, dependent: :destroy
  has_many :users, through: :chat_channel_memberships

  has_many :active_memberships, lambda {
                                  where status: "active"
                                }, class_name: "ChatChannelMembership", inverse_of: :chat_channel
  has_many :pending_memberships, lambda {
                                   where status: "pending"
                                 }, class_name: "ChatChannelMembership", inverse_of: :chat_channel
  has_many :rejected_memberships, lambda {
                                    where status: "rejected"
                                  }, class_name: "ChatChannelMembership", inverse_of: :chat_channel
  has_many :mod_memberships, -> { where role: "mod" }, class_name: "ChatChannelMembership", inverse_of: :chat_channel
  has_many :requested_memberships, lambda {
                                     where status: "joining_request"
                                   }, class_name: "ChatChannelMembership", inverse_of: :chat_channel
  has_many :active_users, through: :active_memberships, class_name: "User", source: :user
  has_many :pending_users, through: :pending_memberships, class_name: "User", source: :user
  has_many :rejected_users, through: :rejected_memberships, class_name: "User", source: :user
  has_many :mod_users, through: :mod_memberships, class_name: "User", source: :user

  has_one :mod_tag, class_name: "Tag", foreign_key: "mod_chat_channel_id",
                    inverse_of: :mod_chat_channel, dependent: :nullify

  validates :channel_type, presence: true, inclusion: { in: CHANNEL_TYPES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :slug, uniqueness: true, presence: true
  validates :description, length: { maximum: 200 }, allow_blank: true
  validates :channel_name, presence: true

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

  def private_org_channel?
    channel_name.to_s.ends_with?(" private group chat") # e.g. @devteam private group chat
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
    chat_channel_memberships.where(user_id: user.id).pick(:last_opened_at)
  end

  def add_users(users)
    now = Time.current
    users_params = Array.wrap(users).map do |user|
      { user_id: user.id, chat_channel_id: id, created_at: now, updated_at: now }
    end

    # memberships that are not unique are automatically skipped
    ChatChannelMembership.insert_all(
      users_params,
      unique_by: :index_chat_channel_memberships_on_chat_channel_id_and_user_id,
    )
  end

  def invite_users(users:, membership_role: "member", inviter: nil)
    invitation_sent = 0
    Array(users).each do |user|
      existing_membership = ChatChannelMembership.find_by(user_id: user.id, chat_channel_id: id)
      if existing_membership.present? && %w[active pending].exclude?(existing_membership.status)
        if existing_membership.update(status: "pending", role: membership_role)
          NotifyMailer.with(membership: existing_membership, inviter: inviter).channel_invite_email.deliver_later
          invitation_sent += 1
        end
      else
        membership = ChatChannelMembership.create(user_id: user.id, chat_channel_id: id, role: membership_role,
                                                  status: "pending")
        if membership.persisted?
          NotifyMailer.with(membership: membership, inviter: inviter).channel_invite_email.deliver_later
          invitation_sent += 1
        end
      end
    end
    invitation_sent
  end

  def remove_user(user)
    chat_channel_memberships.destroy_by(user: user)
  end

  def pusher_channels
    # TODO: use something more unique here (uuid?) rather than just id.
    if invite_only?
      "private-channel--#{ChatChannel.urlsafe_encoded_app_domain}-#{id}"
    elsif open?
      "open-channel--#{ChatChannel.urlsafe_encoded_app_domain}-#{id}"
    else
      chat_channel_memberships.pluck(:user_id).map { |id| ChatChannel.pm_notifications_channel(id) }
    end
  end

  def channel_users_ids
    chat_channel_memberships.pluck(:user_id)
  end

  def adjusted_slug(user = nil, caller_type = "receiver")
    user ||= current_user
    if direct? && caller_type == "receiver"
      cleaned_slug = slug.gsub("/#{user.username}", "").gsub("#{user.username}/", "")
      "@#{cleaned_slug}"
    elsif caller_type == "sender"
      "@#{user.username}"
    else
      slug
    end
  end

  def channel_human_names
    active_memberships
      .order(last_opened_at: :desc).limit(5).includes(:user).map do |membership|
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
    mod_users.ids
  end

  def pending_users_select_fields
    pending_users.select(:id, :username, :name, :updated_at)
  end

  def self.pm_notifications_channel(user_id)
    "private-message-notifications--#{urlsafe_encoded_app_domain}-#{user_id}"
  end

  def self.urlsafe_encoded_app_domain
    Base64.urlsafe_encode64(ApplicationConfig["APP_DOMAIN"])
  end

  private

  def user_obj(membership)
    {
      profile_image: Images::Profile.call(membership.user.profile_image_url, length: 90),
      darker_color: membership.user.decorate.darker_color,
      name: membership.user.name,
      last_opened_at: membership.last_opened_at,
      username: membership.user.username,
      id: membership.user_id
    }
  end
end
