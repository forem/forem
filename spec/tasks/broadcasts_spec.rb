require "rails_helper"

RSpec.describe "Broadcasts tasks", type: :task do
  let(:service) { Broadcasts::WelcomeNotification::Generator }
  let(:one_week_from_today) { 1.week.since }

  let_it_be_readonly(:default_config_date) { SiteConfig.welcome_notifications_live_at }

  before do
    # Set date to a week from today
    SiteConfig.welcome_notifications_live_at = one_week_from_today
    allow(service).to receive(:call)
    Rake::Task.clear
    PracticalDeveloper::Application.load_tasks
  end

  after do
    SiteConfig.welcome_notifications_live_at = default_config_date
  end

  describe "#broadcast_welcome_notification_flow" do
    it "does nothing if SiteConfig.welcome_notifications_live_at is nil" do
      SiteConfig.welcome_notifications_live_at = nil
      create(:user, created_at: 1.day.ago)
      Rake::Task["broadcasts:send_welcome_notification_flow"].invoke
      expect(service).not_to have_received(:call)
    end

    it "does not call upon users created before the start_date" do
      # Travel forward one week, and test that a user created 8 days ago does not receive notifications.
      Timecop.travel(one_week_from_today) do
        create(:user, created_at: 1.day.ago)
        Rake::Task["broadcasts:send_welcome_notification_flow"].invoke
        expect(service).not_to have_received(:call)
      end
    end

    it "call upon users created less than a week ago" do
      # Travel forward one week (7)
      # then travel another week further (14 days)
      # On day 14, pressume user is created 6 days ago (created on day 8)
      # At this point notifications_live_at < week_ago is true and notifications_live_at is ignored.
      Timecop.travel(one_week_from_today + 1.week) do
        create_list(:user, 3, created_at: 6.days.ago)
        create_list(:user, 1, created_at: 10.days.ago)
        Rake::Task["broadcasts:send_welcome_notification_flow"].invoke
        expect(service).to have_received(:call).exactly(3)
      end
    end
  end
end
