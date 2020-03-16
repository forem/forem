require "rails_helper"

RSpec.describe Broadcasts::WelcomeNotification::Generator, type: :service do
  describe "::call" do
    let(:receiving_user) { create(:user) }
    let(:user) { create(:user) }
    let!(:welcome_broadcast) { create(:welcome_broadcast, :active) }

    before do
      allow(User).to receive(:mascot_account).and_return(create(:user))
    end

    context "when sending a set_up_profile notification" do
      xit "generates the appropriate broadcast to be sent to a user"
      xit "it sends a welcome notification for that broadcast"
      xit "it does not send duplicate welcome notification for that broadcast"
      xit "does not send a notification to a user who has set up their profile"
    end

    context "when sending a welcome_thread notification" do
      let(:welcome_thread_article) { create(:article, title: "Welcome Thread") }
      let(:welcome_thread_comment) { create(:comment, commentable: welcome_thread_article, user: user) }
      let(:article) { create(:article) }
      let(:comment) { create(:comment, commentable: article, user: receiving_user) }

      it "generates the correct broadcast type and sends the notification to the user", :aggregate_failures do
        expect(receiving_user.notifications.count).to eq(0)
        sidekiq_perform_enqueued_jobs { described_class.call(receiving_user.id) }

        expect(receiving_user.notifications.count).to eq(1)
        expect(receiving_user.notifications.first.notifiable).to eq(welcome_broadcast)
      end

      it "does not send a notification to a user who has commented in a welcome thread", elasticsearch: true do
        sidekiq_perform_enqueued_jobs { described_class.call(receiving_user.id) }

        expect(user.notifications).to be_empty
      end

      it "does not send a duplicate notification" do
        2.times do
          sidekiq_perform_enqueued_jobs { described_class.call(receiving_user.id) }
        end

        expect(receiving_user.notifications.count).to eq(1)
      end
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
