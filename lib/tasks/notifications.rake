task remove_old_notifications: :environment do
  Notification.fast_destroy_old_notifications
end
