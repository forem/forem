module Notifications
  class Update
    delegate :article_data, :comment_data, :user_data, :organization_data, to: Notifications

    def initialize(notifiable, action = nil)
      @notifiable = notifiable
      @action = action
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      return unless [Article, Comment].include?(notifiable.class)

      notifications = Notification.where(
        notifiable_id: notifiable.id,
        notifiable_type: notifiable.class.name,
        action: action,
      )
      return if notifications.blank?

      new_json_data = notifications.first.json_data || {}
      new_json_data[notifiable.class.name.downcase] = public_send("#{notifiable.class.name.downcase}_data", notifiable)
      new_json_data[:user] = user_data(notifiable.user)
      new_json_data[:organization] = organization_data(notifiable.organization) if notifiable.is_a?(Article) && notifiable.organization_id
      notifications.update_all(json_data: new_json_data)
    end

    private

    attr_reader :notifiable, :action
  end
end
