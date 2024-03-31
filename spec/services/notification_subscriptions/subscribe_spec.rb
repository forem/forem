require "rails_helper"

RSpec.describe NotificationSubscriptions::Subscribe, type: :service do
  let(:current_user) { create(:user) }
  let(:another_user) { create(:user) }
  let(:article) { create(:article, user: current_user) }
  let!(:comment) { create(:comment, user_id: current_user.id, commentable: article) }
  let!(:comment_two) { create(:comment, user_id: another_user.id, commentable: article, parent_id: comment.id) }

  context "when subscribing to a comment" do
    it "creates a notification subscription for the comment" do
      expect do
        described_class.call(current_user, comment_id: comment_two.id)
      end.to change(NotificationSubscription, :count).by(1)

      subscription = NotificationSubscription.last
      expect(subscription.user).to eq(current_user)
      expect(subscription.notifiable).to eq(comment_two)
      expect(subscription.config).to eq("all_comments")
      expect(subscription.notifiable_type).to eq("Comment")
    end
  end

  context "when subscribing to an article" do
    it "creates a notification subscription for the article" do
      expect do
        described_class.call(current_user, article_id: article.id)
      end.to change(NotificationSubscription, :count).by(1)

      subscription = NotificationSubscription.last
      expect(subscription.user).to eq(current_user)
      expect(subscription.notifiable).to eq(article)
      expect(subscription.config).to eq("all_comments")
      expect(subscription.notifiable_type).to eq("Article")
    end

    it "can override subscription config (if valid)" do
      described_class.call(current_user, article_id: article.id, config: "top_level_comments")

      subscription = NotificationSubscription.last
      expect(subscription.config).to eq("top_level_comments")
    end

    it "cannot override subscription config (if invalid)" do
      result = described_class.call(current_user, article_id: article.id, config: "blerg_blurg")

      expect(result).to eq({ errors: "Config is not included in the list" })
    end
  end

  context "when subscribing to a top-level comment" do
    let(:top_level_comment) { create(:comment, parent_id: comment.id) }

    it "creates a notification subscription for the top-level comment" do
      expect do
        described_class.call(current_user, comment_id: top_level_comment.id)
      end.to change(NotificationSubscription, :count).by(1)

      subscription = NotificationSubscription.last
      expect(subscription.user).to eq(current_user)
      expect(subscription.notifiable).to eq(top_level_comment)
      expect(subscription.config).to eq("all_comments")
      expect(subscription.notifiable_type).to eq("Comment")
    end
  end

  # Subscription requires a unique user-id per notifiable-id, but client-side
  # wants this to be idempotent-ish, so...
  context "when already subscribed" do
    let!(:existing_subscription) do
      create(:notification_subscription, user: current_user, notifiable: article)
    end

    it "returns the existing subscription without creating anything new" do
      result = nil # needs to exist before the block or Ruby won't set it
      expect do
        result = described_class.call(current_user, article_id: article.id)
      end.not_to change(NotificationSubscription, :count)

      expect(result).to eq({ updated: true, subscription: existing_subscription })
    end
  end

  context "when parameters are missing" do
    it "does not create a notification subscription" do
      expect do
        expect do
          described_class.call(current_user)
        end.to raise_error(ArgumentError)
      end.not_to change(NotificationSubscription, :count)
    end
  end
end
