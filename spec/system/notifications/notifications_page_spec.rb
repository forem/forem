require "rails_helper"

RSpec.describe "Notifications page", type: :system, js: true do
  let(:alex) { create(:user) }
  let(:leslie) { create(:user) }

  before { sign_in alex }

  def validate_reply(id)
    fill_in "comment-textarea-for-#{id}", with: "thanks i guess"
    click_button("Submit")
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

    expect(page).to have_css("div.spec-notification")
    click_button("heart")

    expect(page).to have_css(".reacted")

    click_link("Reply")

    validate_reply(leslie.comments.first.id)
  end

  it "allows user to follow other users back" do
    follow = leslie.follow(alex)
    Notification.send_new_follower_notification_without_delay(follow, is_read: true)
    visit "/notifications"
    expect(page).to have_css("div.spec-notification")
    click_button("Follow back")
    expect(page).to have_text("Following")
  end

  context "when user is trusted" do
    before do
      dev_user = create(:user)
      allow(User).to receive(:staff_account).and_return(dev_user)
      alex.add_role(:trusted)
    end

    def interact_with_each_emojis
      %w[heart thumbsdown vomit].each do |emoji|
        click_button(emoji)
        expect(page).to have_css(".reacted")
        click_button(emoji)
        expect(page).not_to have_css(".reacted")
      end
    end

    it "allows trusted user to moderate content" do
      article = create(:article, user: alex)
      comment = create(:comment, commentable: article, user: leslie)

      sidekiq_perform_enqueued_jobs

      visit "/notifications"
      expect(page).to have_css("div.spec-notification")

      interact_with_each_emojis
      click_link("Reply")

      validate_reply(comment.id)
    end
  end

  context "with welcome notifications" do
    let(:mascot_account) { create(:user) }

    before do
      allow(Notification).to receive(:send_welcome_notification).and_call_original
      allow(User).to receive(:mascot_account).and_return(mascot_account)
      allow(Settings::Community).to receive(:staff_user_id).and_return(mascot_account.id)
      alex.update!(created_at: 1.day.ago)
    end

    context "without tracking enabled" do
      before do
        create(:welcome_broadcast)
        Broadcasts::WelcomeNotification::Generator.call(alex.id)
        sidekiq_perform_enqueued_jobs
      end

      it "renders the notification" do
        visit "/notifications"

        expect(page).to have_css(".broadcast-content")
        expect(page).to have_css("#welcome_notification_welcome_thread")
      end

      it "does not track events" do
        visit "/notifications"
        click_link("the welcome thread")

        expect(page).to have_current_path("/welcome")
        expect(Ahoy::Event.count).to eq(0)
      end
    end

    context "with tracking enabled" do
      before do
        create(:welcome_broadcast, :with_tracking)
        Broadcasts::WelcomeNotification::Generator.call(alex.id)
        sidekiq_perform_enqueued_jobs
      end

      it "tracks events" do
        visit "/notifications"
        click_link("the welcome thread")

        expect(page).to have_current_path("/welcome")
        expect(Ahoy::Event.count).to eq(1)
      end
    end
  end
end
