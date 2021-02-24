module PushNotifications
  class Send
    def self.call(user:, title:, body:, payload:)
      new(user: user, title: title, body: body, payload: payload).call
    end

    def initialize(user:, title:, body:, payload:)
      @user = user
      @title = title
      @body = body
      @payload = payload
    end

    def call
      @user.devices.each do |device|
        device.create_notification(@title, @body, @payload)
      end

      PushNotifications::DeliverWorker.perform_in(30.seconds)
    end
  end
end
