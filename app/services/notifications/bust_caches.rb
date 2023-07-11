module Notifications
  class BustCaches
    attr_reader :user, :notifiable

    def self.call(...)
      new(...).call
    end

    def initialize(user:, notifiable: nil)
      @user = user
      @notifiable = notifiable
    end

    def call
      raise "not implemented"
    end
  end
end
