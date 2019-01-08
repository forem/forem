class Mention < ApplicationRecord
  belongs_to :user
  belongs_to :mentionable, polymorphic: true

  validates :user_id, presence: true,
                      uniqueness: { scope: %i[mentionable_id
                                              mentionable_type] }
  validates :mentionable_id, presence: true
  validates :mentionable_type, presence: true
  validate :permission
  after_create :send_email_notification

  class << self
    def create_all(notifiable)
      # Only works for comments right now.
      # Paired with the process that creates the "comment-mentioned-user"
      @notifiable = notifiable
      doc = Nokogiri::HTML(notifiable.processed_html)
      usernames = []
      mentions = []
      doc.css(".comment-mentioned-user").each do |link|
        username = link.text.gsub("@", "").downcase
        if user = User.find_by_username(username)
          usernames << username
          mentions << create_mention(user)
        end
      end
      delete_removed_mentions(usernames)
      mentions
    end
    handle_asynchronously :create_all

    private

    def delete_removed_mentions(usernames)
      user_ids = User.where(username: usernames).pluck(:id)
      mentions = @notifiable.mentions.where.not(user_id: user_ids).destroy_all
      Notification.remove_each(mentions) unless mentions.blank?
    end

    def create_mention(user)
      mention = Mention.create(user_id: user.id, mentionable_id: @notifiable.id, mentionable_type: @notifiable.class.name)
      # mentionable_type = model that created the mention, user = user to be mentioned
      Notification.send_mention_notification(mention)
      mention
    end
  end

  def send_email_notification
    if User.find(user_id).email.present? && User.find(user_id).email_mention_notifications
      NotifyMailer.new_mention_email(self).deliver
    end
  end
  handle_asynchronously :send_email_notification

  def permission
    if !mentionable.valid?
      errors.add(:mentionable_id, "is not valid.")
    end
  end
end
