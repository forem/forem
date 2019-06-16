module Notifications
  class Send

    delegate :user_data, to: Notifications
    delegate :comment_data, to: Notifications
    attr_reader :mention

    def initialize(mention)
      @mention = mention
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      Notification.create(
        user_id: mention.user_id,
        notifiable_id: mention.id,
        notifiable_type: "Mention",
        action: nil,
        json_data: json_data
      )
    end

    private 

    def json_data
      if mention.mentionable_type == "Comment"
        return {
          comment: comment,
          user: user
        }

      else
        return { user: user }
      end
    end

    def comment
      comment_data(mention.mentionable)
    end

    def user
      user_data(mention.user_id)
    end
  end
end