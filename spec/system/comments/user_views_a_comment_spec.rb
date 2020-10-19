require "rails_helper"

RSpec.describe "Viewing a comment", type: :system, js: true do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id, show_comments: true) }
  let(:comment) { create(:comment, commentable: article, user: user) }

  before do
    Timecop.freeze
    sign_in user
    visit comment.path
  end

  after do
    Timecop.return
  end

  context "when showing the date" do
    it "shows all published data" do
      comment_date = comment.readable_publish_date.gsub("  ", " ")
      timestamp = comment.decorate.published_timestamp

      expect(page).to have_selector(".comment-date time", text: comment_date)
      expect(page).to have_selector(".comment-date time[datetime='#{timestamp}']")
    end
  end
end
