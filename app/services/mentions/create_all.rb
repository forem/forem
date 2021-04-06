module Mentions
  class CreateAll
    def initialize(notifiable)
      @notifiable = notifiable
    end

    def self.call(...)
      new(...).call
    end

    def call
      # Only works for comments right now.
      mentioned_users = users_mentioned_in_text_excluding_author

      delete_mentions_removed_from_notifiable_text(mentioned_users)
      create_mentions_for(mentioned_users)
    end

    private

    def users_mentioned_in_text_excluding_author
      mentioned_usernames = extract_usernames_from_mentions_in_text

      collect_existing_users(mentioned_usernames)
        .yield_self do |existing_mentioned_users|
          reject_notifiable_author(existing_mentioned_users)
        end
    end

    def collect_existing_users(usernames)
      User.registered.where(username: usernames)
    end

    def create_mentions_for(users)
      users.each { |user| create_mention_for(user) }
    end

    def extract_usernames_from_mentions_in_text
      # The "mentioned-user" css is added by Html::Parser#user_link_if_exists
      doc = Nokogiri::HTML(notifiable.processed_html)
      doc.css(".mentioned-user").map do |link|
        link.text.delete("@").downcase
      end
    end

    def reject_notifiable_author(users)
      users.reject { |user| authored_by?(user, @notifiable) }
    end

    def authored_by?(user, notifiable)
      user.id == notifiable.user_id
    end

    def delete_mentions_removed_from_notifiable_text(users)
      mentions = @notifiable.mentions.where.not(user_id: users).destroy_all
      Notification.remove_all(notifiable_ids: mentions.map(&:id), notifiable_type: "Mention") if mentions.present?
    end

    def user_has_comment_notifications?(user)
      user.notifications.exists?(notifiable_id: @notifiable.id)
    end

    def create_mention_for(user)
      return if user_has_comment_notifications?(user)

      mention = Mention.create(user_id: user.id, mentionable_id: @notifiable.id,
                               mentionable_type: @notifiable.class.name)
      # mentionable_type = model that created the mention, user = user to be mentioned
      Notification.send_mention_notification(mention)
      mention
    end

    attr_reader :notifiable
  end
end
