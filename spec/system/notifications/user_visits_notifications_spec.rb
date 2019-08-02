require "rails_helper"

RSpec.describe "Visiting notifications", type: :system do
  let_it_be(:user) { create(:user) }
  let_it_be(:other_user) { create(:user) }

  before do
    user.follow(other_user)
    sign_in user
    Timecop.travel(10.minutes.ago)
  end

  after do
    Timecop.return
  end

  context "when visiting post notifications" do
    let(:article) { create(:article, :with_notification_subscription, user: other_user) }

    before do
      Notification.send_to_followers_without_delay(article, "Published")
      visit "/notifications/posts"
    end

    it "shows the timestamp in a human readable format", js: true do
      expect(page).to have_selector(".time-ago-indicator", text: "(10 mins ago)")
    end
  end

  context "when visiting comment notifications" do
    let(:article) { create(:article, :with_notification_subscription, user: user) }
    let(:comment) { create(:comment, commentable: article, user: other_user) }

    before do
      Notification.send_new_comment_notifications_without_delay(comment)
      visit "/notifications/comments"
    end

    it "shows the timestamp in a human readable format", js: true do
      expect(page).to have_selector(".time-ago-indicator", text: "(10 mins ago)")
    end
  end
end
