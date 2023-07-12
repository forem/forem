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

  describe ".for_notifiable" do
    before do
      subscription.save!
    end

    it "can find subscription if given a notifiable object" do
      results = described_class.for_notifiable(subscription.notifiable)
      expect(results).to contain_exactly(subscription)
    end

    it "can find subscription if given id & type" do
      bad_results1 = described_class.for_notifiable(notifiable_type: "Article")
      expect(bad_results1).to eq([])

      bad_results2 = described_class.for_notifiable(notifiable_id: article.id)
      expect(bad_results2).to eq([])

      results = described_class.for_notifiable(notifiable_type: "Article", notifiable_id: article.id)
      expect(results).to contain_exactly(subscription)
    end
  end

  it "update_notification_subscriptions calls UpdateWorker later" do
    allow(NotificationSubscriptions::UpdateWorker).to \
      receive(:perform_async)

    notifiable = build(:article, id: 123)

    described_class.update_notification_subscriptions(notifiable)

    expect(NotificationSubscriptions::UpdateWorker).to \
      have_received(:perform_async)
      .with(123, "Article")
  end
end
