require "rails_helper"

RSpec.describe Follow do
  let(:user) { create(:user) }
  let(:tag) { create(:tag) }
  let(:user_2) { create(:user) }
  let(:suspended_user) { create(:user) }

  before do
    suspended_user.add_role(:suspended)
  end

  describe "validations" do
    subject { user.follow(user_2) }

    it { is_expected.to validate_inclusion_of(:subscription_status).in_array(%w[all_articles none]) }
    it { is_expected.to validate_presence_of(:followable_type) }
    it { is_expected.to validate_presence_of(:follower_type) }
    it { is_expected.to validate_presence_of(:subscription_status) }
  end

  it "follows user" do
    user.follow(user_2)
    expect(user.following?(user_2)).to be(true)
  end

  it "calculates points with explicit and implicit combined" do
    user.follow(tag)
    follow = described_class.last
    follow.explicit_points = 2.0
    follow.implicit_points = 3.0
    follow.save
    expect(follow.points).to eq(5.0)
  end

  context "when enqueuing jobs" do
    it "enqueues send notification worker" do
      expect do
        described_class.create(follower: user, followable: user_2)
      end.to change(Follows::SendEmailNotificationWorker.jobs, :size).by(1)
    end
  end

  context "when creating and inline" do
    it "touches the follower user while creating" do
      timestamp = 1.day.ago
      user.update_columns(updated_at: timestamp, last_followed_at: timestamp)
      described_class.create!(follower: user, followable: user_2)

      user.reload
      expect(user.updated_at).to be > timestamp
      expect(user.last_followed_at).to be > timestamp
    end

    it "sends an email notification" do
      allow(ForemInstance).to receive(:smtp_enabled?).and_return(true)
      user_2.notification_setting.update(email_follower_notifications: true)
      expect do
        Sidekiq::Testing.inline! do
          described_class.create!(follower: user, followable: user_2)
        end
      end.to change(EmailMessage, :count).by(1)
    end
  end

  describe "scopes" do
    describe ".non_suspended" do
      before do
        user.follow(user_2)
        user.follow(tag)
        suspended_user.follow(user_2)
      end

      it "excludes suspended users from the result" do
        result = described_class.non_suspended(user_2.class.name, user_2.id)
        expect(result.map(&:follower)).to include(user)
        expect(result.map(&:follower)).not_to include(suspended_user)
      end

      it "filters by followable type and id" do
        result = described_class.non_suspended("ActsAsTaggableOn::Tag", tag.id)
        expect(result.map(&:follower)).to include(user)
        expect(result.map(&:follower)).not_to include(user_2)
        expect(result.map(&:follower)).not_to include(suspended_user)
      end

      it "includes only Users in the result" do
        result = described_class.non_suspended(user_2.class.name, user_2.id)
        expect(result.map(&:follower).all?(User)).to be(true)
      end

      # Additional test cases for more edge cases
    end
  end
end
