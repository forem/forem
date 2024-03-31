require "rails_helper"

RSpec.describe Notifications::NewFollower::Send, type: :service do
  let(:user)            { create(:user) }
  let(:user2)           { create(:user) }
  let(:user3)           { create(:user) }
  let(:organization)    { create(:organization) }
  let(:article)         { create(:article, user_id: user.id, page_views_count: 4000, public_reactions_count: 70) }
  let!(:follow)         { user.follow(user2) }

  def follow_data(follow)
    {
      followable_id: follow.followable_id,
      followable_type: follow.followable_type,
      follower_id: follow.follower_id
    }
  end

  context "when trying to pass tag follow data" do
    it "raises an exception" do
      tag = create(:tag)
      tag_follow = user.follow(tag)
      expect do
        described_class.call(follow_data(tag_follow))
      end.to raise_error(Notifications::NewFollower::FollowData::DataError)
    end
  end

  context "when trying to pass follow data as a Hash with keys as strings" do
    it "creates a notification" do
      stringified_follow_data = follow_data(follow).stringify_keys

      expect do
        described_class.call(stringified_follow_data)
      end.to change(Notification, :count).by(1)
    end
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
      expect(notification.read).to be_falsey
      expect(notification.json_data["user"]["id"]).to eq(user.id)
    end

    it "creates a read notification" do
      notification = described_class.call(follow_data(follow), is_read: true)
      expect(notification.read).to be_truthy
    end

    context "when destroyed follow" do
      let(:unfollow) { user.stop_following(user2) }

      it "does not create a notification" do
        expect do
          described_class.call(follow_data(unfollow))
        end.not_to change(Notification, :count)
      end

      it "destroys notification if it exists" do
        create(:notification, action: "Follow", user: user2, notifiable: follow, notified_at: 1.year.ago)
        expect do
          described_class.call(follow_data(unfollow))
        end.to change(Notification, :count).by(-1)
      end

      it "destroys the correct notification" do
        notification = create(:notification, action: "Follow", user: user2, notifiable: follow, notified_at: 1.year.ago)
        described_class.call(follow_data(unfollow))
        expect(Notification.where(id: notification.id)).not_to exist
      end
    end
  end

  context "when 2 user follows another user" do
    let!(:follow2) { user3.follow user2 }
    let(:follower_data) do
      {
        "id" => user3.id,
        "class" => { "name" => "User" },
        "name" => user3.name,
        "username" => user3.username,
        "path" => user3.path,
        "profile_image_90" => user3.profile_image_90,
        "comments_count" => user3.comments_count
      }
    end

    it "creates a notification" do
      expect do
        described_class.call(follow_data(follow2))
      end.to change(Notification, :count).by(1)
    end

    it "creates a notification with data" do
      notification = described_class.call(follow_data(follow2))
      expect(notification.notifiable).to eq(follow2)
      expect(notification.notified_at).not_to be_nil
      expect(notification.json_data["aggregated_siblings"].pluck("id").sort).to eq([user.id, user3.id].sort)
    end

    it "creates a notification with user data" do
      notification = described_class.call(follow_data(follow2))
      expect(notification.json_data["user"]["name"]).to eq(user3.name)
      expect(notification.json_data["user"]["username"]).to eq(user3.username)
      expect(notification.json_data["user"]["id"]).to eq(user3.id)
      expect(notification.json_data["user"]["class"]).to eq("name" => "User")
    end

    it "does not include suspended users in aggregated_siblings" do
      # Initial Setup: Let's assume user4 and user3 are following user2.
      user4 = create(:user)
      user5 = create(:user)
      user6 = create(:user)
      user4.follow(user2)
      user5.follow(user2)
      user6.follow(user2)

      # Now, suspend user4
      user5.add_role(:suspended)

      # Trigger the described_class call for a new follow event, let's say from user3 to user2.
      notification = described_class.call(follow_data(follow2)) # Assuming follow2 is from user3 to user2

      # Aggregate names of siblings from the JSON data in the notification
      aggregated_sibling_names = notification.json_data["aggregated_siblings"].pluck("name")

      # Expectations: user4 should not be in the aggregated_siblings, but user3 should.
      expect(aggregated_sibling_names).not_to include(user5.name)
      expect(aggregated_sibling_names).to include(user4.name)
      expect(aggregated_sibling_names).to include(user6.name)
    end

    context "when notification exists" do
      before do
        create(:notification, user: user2, action: "Follow", notifiable: follow, notified_at: 1.year.ago)
      end

      it "does not create a notification" do
        expect do
          described_class.call(follow_data(follow2))
        end.not_to change(Notification, :count)
      end

      it "updates a notification" do
        notification = described_class.call(follow_data(follow2))
        expect(notification.notifiable).to eq(follow2)
        expect(notification.notified_at).to be >= 1.day.ago
      end
    end

    context "when destroyed follow and notification exists" do
      it "does not destroy a notification" do
        create(:notification, action: "Follow", user: user2, notifiable: follow, notified_at: 1.year.ago)

        expect do
          unfollow = user.stop_following(user2)
          described_class.call(follow_data(unfollow))
        end.not_to change(Notification, :count)
      end
    end
  end
end
