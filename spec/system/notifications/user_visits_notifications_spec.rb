require "rails_helper"

RSpec.describe "User visits notifications", type: :system do
  let(:reader) { create(:user) }
  let(:author) { create(:user) }
  let(:article) { create(:article, :with_notification_subscription, user: author) }
  let(:comment) { create(:comment, commentable: article, user: reader) }

  before do
    reader.follow(author)
    article.update_column(:published_at, 10.minutes.ago)
    comment.update_column(:created_at, 10.minutes.ago)
  end

  context "when viewing post notifications" do
    before do
      Notification.send_to_followers_without_delay(article, "Published")
      sign_in reader
      visit "/notifications/posts"
    end

    it "shows the timestamp in a human-readable format", js: true do
      expect(page).to have_selector(".time-ago-indicator", text: "(10 mins ago)")
    end
  end

  context "when viewing comment notifications" do
    before do
      Notification.send_new_comment_notifications_without_delay(comment)
      sign_in author
      visit "/notifications/comments"
    end

    it "shows the timestamp in a human-readable format", js: true do
      expect(page).to have_selector(".time-ago-indicator", text: "(10 mins ago)")
    end
  end
end
