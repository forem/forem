require "rails_helper"

RSpec.describe Broadcasts::WelcomeNotification::Generator, type: :service do
  describe "::call" do
    let(:user)               { create(:user) }
    let(:mascot_account)     { create(:user) }

    before do
      allow(User).to receive(:mascot_account).and_return(mascot_account)
      SiteConfig.staff_user_id = mascot_account.id
    end

    after do
      # SiteConfig.clear_cache should work here but for some reason it isn't
      SiteConfig.staff_user_id = 1
    end

    context "when sending a welcome_thread notification" do
      let!(:welcome_broadcast) { create(:welcome_broadcast, :active) }
      let!(:welcome_thread) { create(:article, user: mascot_account, published: true, tags: "welcome") }

      it "generates the correct broadcast type and sends the notification to the user" do
        sidekiq_perform_enqueued_jobs { described_class.call(user.id) }
        expect(user.notifications.first.notifiable).to eq(welcome_broadcast)
      end

      it "does not send a notification to a user who has commented in a welcome thread" do
        create(:comment, commentable: welcome_thread, commentable_type: "Article", user: user)
        expect do
          sidekiq_perform_enqueued_jobs { described_class.call(user.id) }
        end.not_to change(user.notifications, :count)
      end

      it "does not send a duplicate notification" do
        2.times do
          sidekiq_perform_enqueued_jobs { described_class.call(user.id) }
        end

        expect(user.notifications.count).to eq(1)
      end
    end

    context "when sending a set_up_profile notification" do
      xit "generates the appropriate broadcast to be sent to a user"
      xit "it sends a welcome notification for that broadcast"
      xit "it does not send duplicate welcome notification for that broadcast"
      xit "does not send a notification to a user who has set up their profile"
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
