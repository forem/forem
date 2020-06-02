require "rails_helper"

RSpec.describe "Notifications page", type: :system, js: true do
  let(:alex) { create(:user) }
  let(:leslie) { create(:user) }

  before { sign_in alex }

  def validate_reply(id)
    fill_in "comment-textarea-for-#{id}", with: "thanks i guess"
    click_button("SUBMIT")
    expect(page).to have_css("div.reply-sent-notice")

    click_link("Check it out")
    expect(page).to have_text("thanks i guess")
  end

  it "shows 1 notification and disappear after clicking it" do
    follow_instance = leslie.follow(alex)
    Notification.send_new_follower_notification_without_delay(follow_instance)

    visit "/"
    expect(page).to have_css("span#notifications-number", text: "1")
    click_link("notifications-link")
    expect(page).not_to have_css("span#notifications-number", text: "1")
  end

  it "allows user to interact with replies" do
    sidekiq_perform_enqueued_jobs do
      article = create(:article, user: alex)
      comment = create(:comment, commentable: article, user: alex)
      reply = create(:comment, commentable: article, user: leslie, parent: comment)
      Notification.send_new_comment_notifications_without_delay(reply)
    end

    visit "/notifications"

    expect(page).to have_css("div.single-notification")
    click_button("heart")

    expect(page).to have_css("img.reacted-emoji")

    click_link("Reply")

    validate_reply(leslie.comments.first.id)
  end

  it "allows user to follow other users back" do
    follow = leslie.follow(alex)
    Notification.send_new_follower_notification_without_delay(follow, "Published")
    visit "/notifications"
    expect(page).to have_css("div.single-notification")
    click_button("+ FOLLOW BACK")
    expect(page).to have_text("FOLLOWING")
  end

  context "when user is trusted" do
    before do
      dev_user = create(:user)
      allow(User).to receive(:dev_account).and_return(dev_user)
      alex.add_role(:trusted)
    end

    def interact_with_each_emojis
      %w[heart thumbsdown vomit].each do |emoji|
        click_button(emoji)
        expect(page).to have_css("img.reacted-emoji")
        click_button(emoji)
        expect(page).not_to have_css("img.reacted-emoji")
      end
    end

    it "allows trusted user to moderate content" do
      article = create(:article, user: alex)
      comment = create(:comment, commentable: article, user: leslie)

      sidekiq_perform_enqueued_jobs

      visit "/notifications"
      expect(page).to have_css("div.single-notification")

      interact_with_each_emojis
      click_link("Reply")

      validate_reply(comment.id)
    end
  end
end
