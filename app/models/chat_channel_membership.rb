class ChatChannelMembership < ApplicationRecord
  include AlgoliaSearch
  belongs_to :chat_channel
  belongs_to :user

  validates :user_id, presence: true, uniqueness: { scope: :chat_channel_id }
  validates :chat_channel_id, presence: true, uniqueness: { scope: :user_id }
  validates :status, inclusion: { in: %w[active inactive pending rejected left_channel] }
  validates :role, inclusion: { in: %w[member mod] }
  validate  :permission

  algoliasearch index_name: "SecuredChatChannelMembership_#{Rails.env}", auto_index: false do
    attribute :id, :status, :viewable_by, :chat_channel_id, :last_opened_at,
              :channel_text, :channel_last_message_at, :channel_status, :channel_type, :channel_username,
              :channel_text, :channel_name, :channel_image, :channel_modified_slug, :channel_messages_count
    searchableAttributes %i[channel_text]
    attributesForFaceting ["filterOnly(viewable_by)", "filterOnly(status)", "filterOnly(channel_status)", "filterOnly(channel_type)"]
    ranking ["desc(channel_last_message_at)"]
  end

  private

  def channel_last_message_at
    chat_channel.last_message_at
  end

  def channel_status
    chat_channel.status
  end

  def channel_type
    chat_channel.channel_type
  end

  def channel_text
    "#{chat_channel.channel_name} #{chat_channel.slug} #{chat_channel.channel_human_names}"
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
      ProfileImage.new(other_user).get(90)
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

  def channel_color
    if chat_channel.channel_type == "direct"
      other_user&.decorate&.darker_color
    else
      "#111111"
    end
  end

  def channel_modified_slug
    if chat_channel.channel_type == "direct"
      "@" + other_user&.username
    else
      chat_channel.slug
    end
  end

  def viewable_by
    user_id
  end

  def other_user
    chat_channel.users.where.not(id: user_id).first
  end

  def permission
    errors.add(:user_id, "is not allowed in chat") if chat_channel.direct? && chat_channel.slug.split("/").exclude?(user.username)
    # To be possibly implemented in future
    # if chat_channel.users.size > 128
    #   errors.add(:base, "too many members in channel")
    # end
  end
end
