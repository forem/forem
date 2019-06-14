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
      # Paired with the process that creates the "comment-mentioned-user"
      doc = Nokogiri::HTML(notifiable.processed_html)
      usernames = []
      mentions = []
      doc.css(".comment-mentioned-user").each do |link|
        username = link.text.delete("@").downcase
        if (user = User.find_by(username: username))
          usernames << username
          mentions << create_mention(user)
        end
      end
      delete_removed_mentions(usernames)
      mentions
    end

    private

    def delete_removed_mentions(usernames)
      users = User.where(username: usernames)
      mentions = @notifiable.mentions.where.not(user_id: users).destroy_all
      Notification.remove_each(mentions) if mentions.present?
    end

    def create_mention(user)
      mention = Mention.create(user_id: user.id, mentionable_id: @notifiable.id, mentionable_type: @notifiable.class.name)
      # mentionable_type = model that created the mention, user = user to be mentioned
      Notification.send_mention_notification(mention)
      mention
    end

    attr_reader :notifiable
  end
end
