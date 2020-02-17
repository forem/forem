require "rails_helper"

RSpec.describe Broadcasts::WelcomeNotification::Generator, type: :service do
  describe "::call" do
    subject(:welcome_notification) { WelcomeNotification.new(user_id(broadcast_id)) }

    let(:user) { create(:user) }
    let(:broadcast) { create(:broadcast, :welcome_broadcast) } # why does eager loading throw a rubocop error here?
    let(:article) { create(:article) }
    let(:not_commented_on) { create(:comment, commentable: article, title: "Welcome Thread") }
    let(:commented_on) { create(:comment, user: user, commentable: article, title: "Welcome Thread") }

    context "when sending a set_up_profile notification" do
      xit "generates the appropriate broadcast to be sent to a user"
      xit "it sends a welcome notification for that broadcast"
      xit "it does not send duplicate welcome notification for that broadcast"
      xit "does not send a notification to a user who has set up their profile"
    end

    context "when sending a welcome_thread notification", :aggregate_failures do
      xit "generates the appropriate broadcast to be sent to a user"
      xit "sends a welcome notification for that broadcast" do
        expect(welcome_notification.call).to be_success
      end

      xit "does not send duplicate welcome notification for that broadcast" do
        expect(user).to have_received(:call).with(broadcast).once
      end

      xit "does not send a notification to a user who has commented in a welcome thread" do
        # expect(user)
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
