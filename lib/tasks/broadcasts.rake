desc "Send Welcome Notifications"
task broadcast_welcome_notification_flow: :environment do
  User.where("created_at < ?", 7.days.ago).find_each do |user|
    Broadcasts::WelcomeNotification::Generator.call(user.id)
  end
end
