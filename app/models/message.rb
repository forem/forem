class Message < ApplicationRecord
  belongs_to :user
  belongs_to :chat_channel

  validates :message_html, presence: true, length: { maximum: 600 }
  validates :message_markdown, presence: true

  before_validation :evaluate_markdown

  def timestamp
    created_at.strftime("%H:%M:%S")
  end

  private

  def evaluate_markdown
    self.message_markdown = message_html
  end
end
