require "rails_helper"

RSpec.describe Notifications::NewFollower, type: :service do
  let(:user)            { create(:user) }
  let(:user2)           { create(:user) }
  let(:user3)           { create(:user) }
  let(:organization)    { create(:organization) }
  let(:article)         { create(:article, user_id: user.id, page_views_count: 4000, positive_reactions_count: 70) }
  let!(:follow)         { user.follow(user2) }

  def follow_data(follow)
    {
      followable_id: follow.followable_id,
      followable_type: follow.followable_type,
      follower_id: follow.follower_id
    }
  end

  context "when user follows another user" do
    it "creates a notification" do
      expect do
        described_class.call(follow_data(follow))
      end.to change(Notification, :count).by(1)
    end

    it "creates a notification with data" do
      notification = described_class.call(follow_data(follow))
      expect(notification.notifiable).to eq(follow)
      expect(notification.notified_at).not_to be_nil
      expect(notification.json_data["user"]["id"]).to eq(user.id)
    end

    context "when destroyed follow" do
      let(:unfollow) { user.stop_following(user2) }

      it "does not create a notification" do
        expect do
          described_class.call(follow_data(unfollow))
        end.not_to change(Notification, :count)
      end

      context "when notification exists" do
        let!(:notification) { create(:notification, action: "Follow", user: user2, notifiable: follow, notified_at: Time.now - 1.year) }

        it "destroys notification if it exists" do
          expect do
            described_class.call(follow_data(unfollow))
          end.to change(Notification, :count).by(-1)
        end

        it "destroys notification" do
          described_class.call(follow_data(unfollow))
          expect(Notification.where(id: notification.id)).not_to exist
        end
      end
    end
  end

  context "when 2 user follows another user" do
    let!(:follow2) { user3.follow user2 }

    it "creates a notification" do
      expect do
        described_class.call(follow_data(follow2))
      end.to change(Notification, :count).by(1)
    end

    it "creates a notification with data" do
      notification = described_class.call(follow_data(follow2))
      expect(notification.notifiable).to eq(follow2)
      expect(notification.notified_at).not_to be_nil
      expect(notification.json_data["aggregated_siblings"].map { |j| j["id"] }).to eq([user.id, user3.id])
    end

    context "when notification exists" do
      before do
        create(:notification, user: user2, action: "Follow", notifiable: follow, notified_at: Time.now - 1.year)
      end

      it "does not create a notification" do
        expect do
          described_class.call(follow_data(follow2))
        end.not_to change(Notification, :count)
      end

      it "updates a notification" do
        notification = described_class.call(follow_data(follow2))
        expect(notification.notifiable).to eq(follow2)
        expect(notification.notified_at).to be >= Time.now - 1.day
        # p notification.json_data
      end
    end

    context "when destroyed follow and notification exists" do
      let(:unfollow) { user.stop_following(user2) }

      before do
        create(:notification, action: "Follow", user: user2, notifiable: follow, notified_at: Time.now - 1.year)
      end

      it "does not destroy a notification" do
        expect do
          described_class.call(follow_data(unfollow))
        end.not_to change(Notification, :count)
      end
    end
  end
end
