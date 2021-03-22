module Notifications
  class Update
    delegate :article_data, :comment_data, :user_data, :organization_data, to: Notifications

    def initialize(notifiable, action = nil)
      @notifiable = notifiable
      @action = action
    end

    def self.call(...)
      new(...).call
    end

    def call
      return unless [Article, Comment].include?(notifiable.class)

      notifications = Notification.where(
        notifiable_id: notifiable.id,
        notifiable_type: notifiable.class.name,
        action: action,
      )
      # as we only select the first notification right after, there is no need
      # to load all of them in memory with `.blank?`, thus we choose `.none?`
      return if notifications.none?

      new_json_data = {}
      new_json_data[notifiable.class.name.downcase] = public_send("#{notifiable.class.name.downcase}_data", notifiable)
      new_json_data[:user] = user_data(notifiable.user)
      add_organization_data = notifiable.is_a?(Article) && notifiable.organization
      new_json_data[:organization] = organization_data(notifiable.organization) if add_organization_data

      notifications.update_all(json_data: new_json_data)
    end

    private

    attr_reader :notifiable, :action
  end
end
