require "rails_helper"

# TODO: [@thepracticaldev/delightful] Reuse this shared example across all notifications,
# since it should be tested against every kind of broadcast we could send.
RSpec.shared_examples "unsubscribed from welcome notifications" do |_broadcast|
  it "does not send a notification to an unsubscribed user" do
    expect do
      sidekiq_perform_enqueued_jobs { described_class.call(unsubscribed_user.id) }
    end.to not_change(unsubscribed_user.notifications, :count)
  end
end

RSpec.describe Broadcasts::WelcomeNotification::Generator, type: :service do
  describe "::call" do
    let(:user) { create(:user) }
    let(:unsubscribed_user) { create(:user, welcome_notifications: false) }
    let(:mascot_account) { create(:user) }
    let!(:welcome_broadcast) { create(:welcome_broadcast, :active) }

    before do
      allow(User).to receive(:mascot_account).and_return(mascot_account)
      SiteConfig.staff_user_id = mascot_account.id
    end

    after do
      SiteConfig.staff_user_id = 1
    end

    context "when sending a set_up_profile notification" do
      xit "generates the appropriate broadcast to be sent to a user"
      xit "it sends a welcome notification for that broadcast"
      xit "it does not send duplicate welcome notification for that broadcast"
      xit "does not send a notification to a user who has set up their profile"
    end

    context "when sending a welcome_thread notification" do
      it "generates the correct broadcast type and sends the notification to the user", :aggregate_failures do
        expect do
          sidekiq_perform_enqueued_jobs { described_class.call(user.id) }
        end.to change(user.notifications, :count).by(1)

        expect(user.notifications.first.notifiable).to eq(welcome_broadcast)
      end

      it "does not send a notification to a user who has commented in a welcome thread", :aggregate_failures do
        welcome_thread_article = create(:article, title: "Welcome Thread - v0", published: true, tags: "welcome", user: mascot_account)
        create(:comment, commentable: welcome_thread_article, commentable_type: "Article", user: user)

        expect do
          sidekiq_perform_enqueued_jobs { described_class.call(user.id) }
        end.to not_change(user.notifications, :count)
      end

      it "does not send a duplicate notification" do
        sidekiq_perform_enqueued_jobs { 2.times { described_class.call(user.id) } }
        expect(user.notifications.count).to eq(1)
      end

      it_behaves_like "unsubscribed from welcome notifications"
    end

    context "when sending a twitter_connect notification" do
      xit "generates the appropriate broadcast to be sent to a user"
      xit "it sends a welcome notification for that broadcast"
      xit "it does not send duplicate welcome notification for that broadcast"
      xit "does not send a notification to a user who is connected via twitter"
    end

    context "when sending a github_connect notification" do
      xit "generates the appropriate broadcast to be sent to a user"
      xit "it sends a welcome notification for that broadcast"
      xit "it does not send duplicate welcome notification for that broadcast"
      xit "does not send a notification to a user who is connected via github"
    end
  end
end
