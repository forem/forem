module PushNotifications
  class Send
    def self.call(user = nil, **kwargs)
      new(user, **kwargs).call
    end

    def initialize(user, **kwargs)
      @user = user
      @title = kwargs[:title]
      @subtitle = kwargs[:subtitle]
      @body = kwargs[:body]
      @payload = kwargs[:payload]
    end

    def call
      @user.devices.each do |device|
        n = Rpush::Apns2::Notification.new
        n.app = ios_app
        n.device_token = device.token
        n.data = {
          aps: {
            :alert => {
              title: ApplicationConfig["COMMUNITY_NAME"],
              subtitle: @title,
              body: @body
            },
            "thread-id" => ApplicationConfig["COMMUNITY_NAME"]
          },
          data: @payload
        }
        n.save!
      end
    end

    private

    def ios_app
      @ios_app ||= Rpush::Apns2::App.where(name: "Forem").first || recreate_app
    end

    def recreate_app
      app = Rpush::Apns2::App.new
      app.name = "Forem"
      app.certificate = Base64.decode64(SiteConfig.push_notifications_ios_pem)
      app.environment = "development"
      app.password = ""
      app.bundle_id = "com.forem.app"
      app.connections = 1
      app.save!
      app
    end
  end
end
