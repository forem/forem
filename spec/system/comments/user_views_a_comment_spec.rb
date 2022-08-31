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

  context "when viewing the comment date" do
    it "contains a time tag with the correct value for the datetime attribute" do
      timestamp = comment.decorate.published_timestamp

      expect(page).to have_selector(".comment-date time[datetime='#{timestamp}']")
    end
  end
end
