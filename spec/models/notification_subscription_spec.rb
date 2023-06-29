require "rails_helper"

RSpec.describe NotificationSubscription do
  subject(:subscription) { notification_subscription }

  let(:user) { build(:user) }
  let(:article) { build(:article, user: user) }
  let(:notification_subscription) { build(:notification_subscription, user: user, notifiable: article) }

  it { is_expected.to belong_to(:notifiable) }
  it { is_expected.to belong_to(:user) }

  it "validates config" do
    expect(subscription).to(
      validate_inclusion_of(:config)
        .in_array(%w[all_comments top_level_comments only_author_comments]),
    )
  end

  it { is_expected.to validate_presence_of(:config) }
  it { is_expected.to validate_presence_of(:notifiable_type) }
  it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(%i[notifiable_type notifiable_id]) }

  describe "#notifiable_type" do
    it "is valid if equals to Article" do
      notification_subscription.notifiable_type = "Article"

      expect(notification_subscription).to be_valid
    end

    it "is valid if equals to Comment" do
      comment = create(:comment)
      notification_subscription.notifiable_id = comment.id
      notification_subscription.notifiable_type = "Comment"

      expect(notification_subscription).to be_valid
    end

    it "is is invalid with Podcast" do
      podcast = create(:podcast)
      notification_subscription.notifiable_id = podcast.id
      notification_subscription.notifiable_type = "Podcast"

      expect(notification_subscription).not_to be_valid
    end
  end

  pending "update_notification_subscriptions calls UpdateWorker later"
end
