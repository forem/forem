module RpushHelpers
  def mock_rpush(consumer_app)
    if consumer_app.android?
      rpush_class = Rpush::Gcm::App
      rpush_notification_class = Rpush::Gcm::Notification
      auth_key = :auth_key
    elsif consumer_app.ios?
      rpush_class = Rpush::Apns2::App
      rpush_notification_class = Rpush::Apns2::Notification
      auth_key = :certificate
    end

    rpush_app = rpush_class.new(
      :name => consumer_app.app_bundle,
      auth_key => consumer_app.auth_credentials,
    )
    allow(rpush_app).to receive(:destroy)

    rpush_notification = rpush_notification_class.new
    allow(rpush_notification).to receive(:save!)
    allow(rpush_notification_class).to receive(:new).and_return(rpush_notification)

    relation = double
    allow(relation).to receive(:first).and_return(rpush_app)
    allow(rpush_class).to receive(:where).and_return(relation)

    original = consumer_app.method(:save)
    allow(consumer_app).to receive(:save) do
      rpush_app.public_send("#{auth_key}=", consumer_app.auth_credentials)
      original.call
    end

    {
      rpush_notification: rpush_notification
    }
  end
end
