require "rails_helper"

RSpec.describe Notifications::NewFollower, type: :service do
  let(:user)            { create(:user) }
  let(:user2)           { create(:user) }
  let(:user3)           { create(:user) }
  let(:organization)    { create(:organization) }
  let(:article)         { create(:article, user_id: user.id, page_views_count: 4000, positive_reactions_count: 70) }
  let!(:follow)          { user.follow(user2) }

  context "user follows another user" do
    it "creates a notification" do
      expect {
        described_class.call(follow)
      }.to change(Notification, :count).by(1)
    end

    it "creates a notification with data" do
      notification = described_class.call(follow)
      expect(notification.notifiable).to eq(follow)
      expect(notification.notified_at).not_to be_nil
      expect(notification.json_data["user"]["id"]).to eq(user.id)
    end

    context "destroyed follow" do
      let(:unfollow) { user.stop_following(user2) }

      it "does not create a notification" do
        expect {
          described_class.call(unfollow)
        }.not_to change(Notification, :count)
      end

      context "notification exists" do
        let!(:notification) { create(:notification, action: "Follow", user: user2, notifiable: follow, notified_at: Time.now - 1.year) }

        it "destroys notification if it exists" do
          expect {
            described_class.call(unfollow)
          }.to change(Notification, :count).by(-1)
        end

        it "destroys notification" do
          described_class.call(unfollow)
          expect(Notification.where(id: notification.id).exists?).to be_falsey
        end
      end
    end
  end

  context "2 user follows another user" do
    let!(:follow2) { user3.follow user2 }

    it "creates a notification" do
      expect {
        described_class.call(follow2)
      }.to change(Notification, :count).by(1)
    end

    it "creates a notification with data" do
      notification = described_class.call(follow2)
      expect(notification.notifiable).to eq(follow2)
      expect(notification.notified_at).not_to be_nil
      expect(notification.json_data["aggregated_siblings"].map { |j| j["id"] }).to eq([user.id, user3.id])
    end

    context "notification exists" do
      let!(:notification) { create(:notification, user: user2, action: "Follow", notifiable: follow, notified_at: Time.now - 1.year) }

      it "does not create a notification" do
        expect {
          described_class.call(follow2)
        }.not_to change(Notification, :count)
      end

      it "updates a notification" do
        notification = described_class.call(follow2)
        expect(notification.notifiable).to eq(follow2)
        expect(notification.notified_at).to be >= Time.now - 1.day
        # p notification.json_data
      end
    end

    context "destroyed follow and notification exists" do
      let(:unfollow) { user.stop_following(user2) }
      let!(:notification) { create(:notification, action: "Follow", user: user2, notifiable: follow, notified_at: Time.now - 1.year) }

      it "does not destroy a notification" do
        expect {
          described_class.call(unfollow)
        }.not_to change(Notification, :count)
      end
    end
  end
end
