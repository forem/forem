require "rails_helper"

RSpec.describe Broadcasts::WelcomeNotification::Introduction, type: :service do
  describe "::send" do
    let(:receiving_user) { create(:user) }
    let(:user) { create(:user) }
    let(:mascot_account) { create(:user) }
    let!(:welcome_broadcast) { create(:welcome_broadcast, :active) }

    before do
      allow(User).to receive(:mascot_account).and_return(mascot_account)
      SiteConfig.staff_user_id = mascot_account.id
    end

    after do
      SiteConfig.staff_user_id = 1
    end

    context "when sending a welcome_thread notification" do
      before do
        welcome_thread_article = create(:article, user: mascot_account, published: true, tags: "welcome")
        create(:comment, commentable: welcome_thread_article, commentable_type: "Article", user: user)
      end

      it "generates the correct broadcast type and sends the notification to the user", :aggregate_failures do
        expect(receiving_user.notifications.count).to eq(0)
        sidekiq_perform_enqueued_jobs { described_class.send(receiving_user) }

        expect(receiving_user.notifications.count).to eq(1)
        expect(receiving_user.notifications.first.notifiable).to eq(welcome_broadcast)
      end

      it "does not send a notification to a user who has commented in a welcome thread", :aggregate_failures do
        expect(user.notifications.count).to eq(0)
        sidekiq_perform_enqueued_jobs { described_class.send(user) }
        expect(user.notifications.count).to eq(0)
      end

      it "does not send a duplicate notification" do
        2.times do
          sidekiq_perform_enqueued_jobs { described_class.send(receiving_user) }
        end

        expect(receiving_user.notifications.count).to eq(1)
      end
    end
  end
end
