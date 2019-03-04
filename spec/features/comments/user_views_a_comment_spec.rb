require "rails_helper"

RSpec.describe "Viewing a comment", type: :feature, js: true do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id, show_comments: true) }
  let!(:comment) { create(:comment, commentable: article, user: user) }

  before do
    sign_in user
    visit comment.path
  end

  context "when showing the date" do
    it "shows the readable publish date" do
      # %e blank pads days from 1 to 9, but the double space isn't in the HTML
      comment_date = comment.readable_publish_date.gsub("  ", " ")
      expect(page).to have_selector(".comment-date", text: comment_date)
    end

    it "embeds the published timestamp" do
      Time.use_zone("UTC") do
        ts = comment.decorate.published_timestamp
        timestamp_selector = ".comment-date[data-published-timestamp='#{ts}']"
        expect(page).to have_selector(timestamp_selector)
      end
    end
  end
end
