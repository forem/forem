class ChatChannelMembership < ApplicationRecord
  belongs_to :chat_channel
  belongs_to :user

  validates :user_id, presence: true, uniqueness: { scope: :chat_channel_id }
  validates :chat_channel_id, presence: true, uniqueness: { scope: :user_id }
  validate  :permission

  private

  def permission
    if chat_channel.channel_type == "direct" && chat_channel.slug.split("/").exclude?(user.username)
      errors.add(:user_id, "is not allowed in chat")
    end
  end
end
