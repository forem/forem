require "rails_helper"

RSpec.describe "Viewing a comment", type: :system, js: true do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id, show_comments: true) }
  let(:comment) { create(:comment, commentable: article, user: user) }
  let!(:timestamp) { "2019-03-04T10:00:00Z" }

  before do
    Timecop.freeze(timestamp)
    sign_in user
    visit comment.path
  end

  after do
    Timecop.return
  end

  context "when showing the date" do
    it "shows the readable publish date" do
      expect(page).to have_selector(".comment-date time", text: "Mar 4")
    end

    it "embeds the published timestamp" do
      selector = ".comment-date time[datetime='#{timestamp}']"
      expect(page).to have_selector(selector)
    end
  end
end
