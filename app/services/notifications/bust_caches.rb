module Notifications
  class BustCaches
    attr_reader :user, :notifiable_id, :notifiable_type

    FINDERS = {
      "Article" => Article,
      "Comment" => Comment
    }.freeze

    def self.call(...)
      new(...).call
    end

    def initialize(user:, notifiable: nil, notifiable_id: nil, notifiable_type: nil)
      @user = user
      @notifiable_id = notifiable_id
      @notifiable_type = notifiable_type
      @notifiable = notifiable
    end

    def call
      raise "not implemented"
    end

    def notifiable
      @notifiable ||= FINDERS.fetch(notifiable_type).find(notifiable_id)
    end
  end
end
