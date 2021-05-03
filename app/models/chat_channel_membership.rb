class ChatChannelMembership < ApplicationRecord
  attr_accessor :invitation_usernames

  ROLES = %w[member mod].freeze
  STATUSES = %w[active inactive pending rejected left_channel removed_from_channel joining_request].freeze

  belongs_to :chat_channel
  belongs_to :user

  validates :chat_channel_id, presence: true, uniqueness: { scope: :user_id }
  validates :role, inclusion: { in: ROLES }
  validates :status, inclusion: { in: STATUSES }
  validates :user_id, presence: true

  validate  :permission

  delegate :channel_type, to: :chat_channel

  scope :eager_load_serialized_data, -> { includes(:user, :channel) }
  scope :filter_by_status, ->(status) { where status: status }
  scope :filter_by_role, ->(role) { where role: role }

  def channel_last_message_at
    chat_channel.last_message_at
  end

  def channel_status
    chat_channel.status
  end

  def channel_text
    parsed_channel_name = chat_channel.channel_name&.gsub("chat between", "")&.gsub("and", "")
    "#{parsed_channel_name} #{chat_channel.slug} #{chat_channel.channel_human_names.join(' ')}"
  end

  def channel_name
    if chat_channel.channel_type == "direct"
      "@#{other_user&.username}"
    else
      chat_channel.channel_name
    end
  end

  def channel_image
    if chat_channel.channel_type == "direct"
      Images::Profile.call(other_user.profile_image_url, length: 90)
    else
      ActionController::Base.helpers.asset_path("organization.svg")
    end
  end

  def channel_messages_count
    chat_channel.messages.size
  end

  def channel_username
    other_user&.username if chat_channel.channel_type == "direct"
  end

  def channel_modified_slug
    if chat_channel.channel_type == "direct"
      "@#{other_user&.username}"
    else
      chat_channel.slug
    end
  end

  def viewable_by
    user_id
  end

  def channel_discoverable
    chat_channel.discoverable
  end

  private

  def channel_color
    if chat_channel.channel_type == "direct"
      other_user&.decorate&.darker_color
    else
      "#111111"
    end
  end

  def other_user
    chat_channel.users.where.not(id: user_id).first
  end

  def permission
    return unless chat_channel
    return unless chat_channel.direct? && chat_channel.slug.split("/").exclude?(user.username)

    errors.add(:user_id, "is not allowed in chat")

    # To be possibly implemented in future
    # if chat_channel.users.size > 128
    #   errors.add(:base, "too many members in channel")
    # end
  end
end
