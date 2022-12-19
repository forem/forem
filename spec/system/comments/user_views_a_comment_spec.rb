require "rails_helper"

RSpec.describe "Viewing a comment", type: :system, js: true do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id, show_comments: true) }
  let(:comment) { create(:comment, commentable: article, user: user) }

  before do
    Timecop.freeze
    ENV["DESYNC_TIMEZONE"] = "true"
    mock_user_tz = ActiveSupport::TimeZone[Zonebie.random_timezone].tzinfo.name
    ENV["TZ"] = mock_user_tz
  end

  after do
    ENV["TZ"] = Time.zone.tzinfo.name
    ENV["DESYNC_TIMEZONE"] = nil
    Capybara.current_session.quit
    Timecop.return
  end

  context "when viewing the comment date" do
    it "contains a time tag with the correct value for the datetime attribute" do
      sign_in user
      visit comment.path
      timestamp = comment.decorate.published_timestamp

      expect(page).to have_selector(".comment-date time[datetime='#{timestamp}']")
    end

    it "shows the published date in the user's local time zone" do
      sign_in user
      visit comment.path
      date = comment.created_at.getlocal.strftime("%b %-d")

      expect(page).to have_selector(".comment-date time", text: date)
    end
  end

  context "when a year has passed" do
    before do
      comment
      Timecop.freeze(1.year.from_now)
    end

    it "shows the published date in the correct format" do
      sign_in user
      visit comment.path
      date = comment.created_at.getlocal.strftime("%b %-d '%y")

      expect(page).to have_selector(".comment-date time", text: date)
    end
  end

  context "when the comment is edited and a year has passed" do
    before do
      comment.update(body_markdown: "This message is edited.", edited_at: 1.day.from_now)
      Timecop.freeze(1.year.from_now)
    end

    it "shows the edited date in the correct format" do
      sign_in user
      visit comment.path
      date = comment.edited_at.getlocal.strftime("%b %-d")

      expect(page).to have_content("Edited on #{date}")
    end
  end
end
