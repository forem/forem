class UnreadNotificationsEmailer
  attr_reader :user

  def self.send_all_emails(num = 1000)
    # This will run once a day (defined outside the app)
    # only to users who have made at least one comment or article.
    # We can change this up later.
    users = User.where("comments_count > ? OR reactions_count > ?", 0, 0).order("RANDOM()").limit(num)
    users.find_each do |user|
      begin
        UnreadNotificationsEmailer.new(user).send_email_if_appropriate
      rescue => e
        logger = Logger.new(STDOUT)
        logger = Airbrake::AirbrakeLogger.new(logger)
        logger.error(e)
      end
    end
  end

  def initialize(user)
    @user = user
  end

  def send_email_if_appropriate
    if should_send_email?
      send_email
    end
  end

  def should_send_email?
    return false if !user.email_unread_notifications
    return false if last_email_sent_after(24.hours.ago)
    emailable_notifications_count = 0
    user_activities.each do |activity|
      emailable_notifications_count += 1 if proper_activity(activity)
    end
    emailable_notifications_count > rand(1..6)
  end

  def user_activities
    feed = StreamRails.feed_manager.get_notification_feed(user.id)
    results = feed.get["results"]
    StreamRails::Enrich.new.enrich_aggregated_activities(results)
  end

  def send_email
    NotifyMailer.unread_notifications_email(user).deliver
  end

  private

  def proper_activity(activity)
    activity["verb"] != "Reaction" && activity["is_seen"] == false
  end

  def last_email_sent_after(time)
    last_email = user.email_messages.last
    time_check = last_email && last_email.sent_at && (last_email.sent_at > time)
    time_check.present?
  end
end
