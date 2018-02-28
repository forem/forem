class Broadcast < ApplicationRecord
  has_many :notifications, as: :notifiable

  validates :title, :type_of, :processed_html, presence: true

  def self.send_welcome_notification(user_id)
    welcome_broadcast = Broadcast.find_by(title: "Welcome Notification")
    return if welcome_broadcast == nil
    Notification.create(
      user_id: user_id,
      notifiable_id: welcome_broadcast.id,
      notifiable_type: "Broadcast",
      action: welcome_broadcast.type_of,
    )
  end

  # method not in use; will be in use if we choose to use markdown
  def evaluate_markdown
    return if body_markdown.blank?
    begin
      parsed_markdown = MarkdownParser.new(body_markdown)
      self.processed_html = get_inner_body(parsed_markdown.finalize)
    rescue StandardError => e
      errors[:base] << ErrorMessageCleaner.new(e.message).clean
    end
  end

  def get_inner_body(content)
    Nokogiri::HTML(content).at("body").inner_html
  end
end
