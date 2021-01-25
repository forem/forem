module PushNotifications
  class Send
    def self.call(user = nil, **kwargs)
      new(user, **kwargs).call
    end

    def initialize(user, **kwargs)
      @user = user
      @title = kwargs[:title]
      @body = kwargs[:body]
      @payload = kwargs[:payload]
    end

    def call
      @user.devices.each do |device|
        device.create_notification(@title, @body, @payload)
      end

      PushNotifications::DeliverWorker.perform_in(30.seconds)
    end
  end
end
