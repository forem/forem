module Mentions
  class CreateAll
    def initialize(notifiable)
      @notifiable = notifiable
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      # Only works for comments right now.
      mentioned_users = users_mentioned_in_notifiable_text_that_are_existing_and_not_its_owners

      delete_mentions_removed_from_notifiable_text(mentioned_users)
      create_mentions_for(mentioned_users)
    end

    private

    def users_mentioned_in_notifiable_text_that_are_existing_and_not_its_owners
      mentioned_usernames = extract_usernames_from_mentions_in_text

      collect_existing_users(mentioned_usernames).
        then do |existing_mentioned_users|
          reject_notifiable_owner existing_mentioned_users
        end
    end

    def collect_existing_users(usernames)
      usernames.filter_map do |username|
        User.find_by(username: username)
      end
    end

    def create_mentions_for(users)
      users.map { |user| create_mention_for(user) }
    end

    def extract_usernames_from_mentions_in_text
      # Paired with the process that creates the "comment-mentioned-user"
      doc = Nokogiri::HTML(notifiable.processed_html)
      doc.css(".comment-mentioned-user").map do |link|
        link.text.delete("@").downcase
      end
    end

    def reject_notifiable_owner(users)
      users.reject { |user| user_owns_notifiable?(user, @notifiable) }
    end

    def user_owns_notifiable?(user, notifiable)
      user.id == notifiable.user_id
    end

    def delete_mentions_removed_from_notifiable_text(users)
      mentions = @notifiable.mentions.where.not(user_id: users).destroy_all
      Notification.remove_all(notifiable_ids: mentions.pluck(:id), notifiable_type: "Mention") if mentions.present?
    end

    def create_mention_for(user)
      mention = Mention.create(user_id: user.id, mentionable_id: @notifiable.id, mentionable_type: @notifiable.class.name)
      # mentionable_type = model that created the mention, user = user to be mentioned
      Notification.send_mention_notification(mention)
      mention
    end

    attr_reader :notifiable
  end
end
