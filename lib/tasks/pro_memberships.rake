# All of these tasks need to be scheduled daily
namespace :pro_memberships do
  desc "Notify pro users with insufficient credits that their membership is about to expire in a week"
  task notify_expirations_one_week_before: :environment do
    num_notified = ProMemberships::ExpirationNotifier.call(1.week.from_now)
    Rails.logger.info("Notified #{num_notified} Pro users...")
  end

  desc "Notify pro users with insufficient credits that their membership is about to expire in a day"
  task notify_expirations_one_day_before: :environment do
    num_notified = ProMemberships::ExpirationNotifier.call(1.day.from_now)
    Rails.logger.info("Notified #{num_notified} Pro users...")
  end

  desc "Bill pro users and optionally charge their cards"
  task bill_users: :environment do
    ProMemberships::Biller.call
  end
end
