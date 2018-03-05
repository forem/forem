class Mention < ApplicationRecord
  include StreamRails::Activity
  as_activity

  belongs_to :user
  belongs_to :mentionable, polymorphic: true

  validates :user_id, presence: true,
            uniqueness: { scope: [:mentionable_id,
                                  :mentionable_type] }
  validates :mentionable_id, presence: true
  validates :mentionable_type, presence: true
  after_create :send_email_notification

  class << self
    def create_all(notifiable)
      # Only works for comments right now.
      # Paired with the process that creates the "comment-mentioned-user"
      @notifiable = notifiable
      doc = Nokogiri::HTML(notifiable.processed_html)
      usernames = []
      doc.css(".comment-mentioned-user").each do |link|
        username = link.text.gsub("@","").downcase
        if user = User.find_by_username(link.text.gsub("@","").downcase)
          usernames << username
          create_mention(user)
        end
      end
      delete_removed_mentions(usernames)
    end
    handle_asynchronously :create_all

    private

    def delete_removed_mentions(usernames)
      users = User.where(username:usernames)
      @notifiable.mentions.where.not(user_id:users.pluck(:id)).destroy_all
    end

    def create_mention(user)
      Mention.create(user_id: user.id, mentionable_id: @notifiable.id, mentionable_type: @notifiable.class.name)
    end
  end

  def activity_actor
    mentionable.user
  end

  def activity_notify
    return if mentionable.parent_user && mentionable.parent_user.id == user.id
    [StreamNotifier.new(user.id).notify]
  end

  def activity_object
    mentionable
  end

  def activity_target
    return "mention_#{Time.now}"
  end

  def remove_from_feed
    super
    User.find(user.id)&.touch(:last_notification_activity)
  end

  def send_email_notification
    if User.find(self.user_id).email.present? && User.find(self.user_id).email_mention_notifications
      NotifyMailer.new_mention_email(self).deliver
    end
  end
  handle_asynchronously :send_email_notification
end
