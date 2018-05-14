class Message < ApplicationRecord
  belongs_to :user
  belongs_to :chat_channel

  validates :message_html, presence: true
  validates :message_markdown, presence: true, length: { maximum: 600 }

  before_validation :evaluate_markdown
  before_validation :evaluate_channel_permission

  def timestamp
    created_at.strftime("%H:%M:%S")
  end

  private

  def evaluate_markdown
    self.message_html = message_markdown
  end

  def evaluate_channel_permission
    channel_type = ChatChannel.find(chat_channel_id).channel_type
    return if channel_type == "open"
    if user&.has_role?(:chatroom_beta_tester)
      # this is fine
    else
      errors.add(:base, "You are not a participant of this chat channel.")
    end
  end
end
