require "rails_helper"

RSpec.describe NotificationSubscriptions::Subscribe, type: :service do
  let(:current_user) { create(:user) }
  let(:another_user) { create(:user) }
  let(:article) { create(:article, user: current_user) }
  let!(:comment) { create(:comment, user_id: current_user.id, commentable: article) }
  let!(:comment_two) { create(:comment, user_id: another_user.id, commentable: article, parent_id: comment.id) }

  describe "#call" do
    context "when subscribing to a comment" do
      let(:params) { { comment_id: comment_two.id } }

      it "creates a notification subscription for the comment" do
        expect do
          described_class.call(current_user, params)
        end.to change(NotificationSubscription, :count).by(1)

        subscription = NotificationSubscription.last
        expect(subscription.user).to eq(current_user)
        expect(subscription.notifiable).to eq(comment_two)
        expect(subscription.notifiable_type).to eq("Comment")
      end
    end

    context "when subscribing to an article" do
      let(:params) { { article_id: article.id } }

      it "creates a notification subscription for the article" do
        expect do
          described_class.call(current_user, params)
        end.to change(NotificationSubscription, :count).by(1)

        subscription = NotificationSubscription.last
        expect(subscription.user).to eq(current_user)
        expect(subscription.notifiable).to eq(article)
        expect(subscription.notifiable_type).to eq("Article")
      end
    end

    context "when subscribing to a top-level comment" do
      let(:top_level_comment) { create(:comment, parent_id: comment.id) }
      let(:params) { { comment_id: top_level_comment.id } }

      it "creates a notification subscription for the top-level comment" do
        expect do
          described_class.call(current_user, params)
        end.to change(NotificationSubscription, :count).by(1)

        subscription = NotificationSubscription.last
        expect(subscription.user).to eq(current_user)
        expect(subscription.notifiable).to eq(top_level_comment)
        expect(subscription.notifiable_type).to eq("Comment")
      end
    end

    context "when parameters are missing" do
      it "does not create a notification subscription" do
        expect do
          described_class.call(current_user, {})
        end.not_to change(NotificationSubscription, :count)
      end
    end
  end
end
