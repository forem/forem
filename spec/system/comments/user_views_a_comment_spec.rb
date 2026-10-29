require "rails_helper"

RSpec.describe "Viewing a comment", :js do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id, show_comments: true, with_tags: false, with_main_image: false) }
  let(:comment) { create(:comment, commentable: article, user: user) }

  before do
    Timecop.freeze(Time.current.change(usec: 0))
    ENV["DESYNC_TIMEZONE"] = "true"
    mock_user_tz = ActiveSupport::TimeZone[Zonebie.random_timezone].tzinfo.name
    ENV["TZ"] = mock_user_tz
    page.driver.browser.page.command("Emulation.setTimezoneOverride", timezoneId: mock_user_tz)
  end

  after do
    ENV["TZ"] = Time.zone.tzinfo.name
    ENV["DESYNC_TIMEZONE"] = nil
    Timecop.return
  end

  it "formats current-year, past-year, and edited comment dates in the user's local time zone", :aggregate_failures do
    comment.update(body_markdown: "This message is edited.", edited_at: 1.day.from_now.change(usec: 0))
    Timecop.freeze(1.year.from_now.change(usec: 0))
    current_comment = create(:comment, commentable: article, parent: comment, user: user)

    sign_in user
    visit comment.path
    comment.reload
    current_comment.reload

    current_timestamp = current_comment.decorate.published_timestamp
    current_date = current_comment.created_at.getlocal.strftime("%b %-d")
    within("#comment-node-#{current_comment.id} > .comment__inner") do
      expect(page).to have_css(".comment-date time[datetime='#{current_timestamp}']")
      expect(page).to have_css(".comment-date time", text: current_date)
    end

    past_date = comment.created_at.getlocal.strftime("%b %-d '%y")
    edited_date = comment.edited_at.getlocal.strftime("%b %-d")
    within("#comment-node-#{comment.id} > .comment__inner") do
      expect(page).to have_css(".comment-date time", text: past_date)
      expect(page).to have_content("Edited on #{edited_date}")
    end
  end
end
