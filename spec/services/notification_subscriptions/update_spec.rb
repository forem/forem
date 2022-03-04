require "rails_helper"

RSpec.describe NotificationSubscriptions::Update, type: :service do
  let(:original_author) { create(:user) }
  let(:reassigned_author) { create(:user) }
  let(:article) { create(:article, user: original_author) }

  context "when updating notification subscriptions of an article" do
    it "updates all notification subscriptions for the article", :aggregate_failures do
      notification_subscription = create(
        :notification_subscription,
        notifiable: article,
        user: original_author,
      )

      expect do
        article.assign_attributes(user: reassigned_author)
        described_class.call(article)
        notification_subscription.reload
      end
        .to change { notification_subscription.user_id }.from(original_author.id).to(reassigned_author.id)
    end
  end
end
