require "rails_helper"

RSpec.describe "Like button and tooltip after replying", js: true do
  let(:author)  { create(:user) }
  let!(:article) { create(:article, user: author, show_comments: true) }
  let!(:parent_comment) { create(:comment, commentable: article) }
  let!(:sibling_comment) { create(:comment, commentable: article) }

  before { sign_in author }

  it "keeps the like footer visible and clears replying state on parent after submitting a reply" do
    visit article.path.to_s
    wait_for_javascript

    # Open reply form on the parent comment and submit a reply
    within "#comment-node-#{parent_comment.id}" do
      find(".toggle-reply-form").click
    end

    find(:xpath, "//textarea[contains(@id, 'textarea-for')]").set("Thanks!")
    click_button("Submit")

    # Parent comment should no longer be in the `replying` state
    within "#comment-node-#{parent_comment.id}" do
      expect(page).to have_css(".comment__details")
      expect(page).not_to have_css(".comment__details.replying")

      # Like button present and visible in the footer
      expect(page).to have_css(".comment__footer .reaction-button", visible: :visible)
    end
  end

  it "sets explicit z-index on comment like buttons for stable tooltip stacking" do
    visit article.path.to_s
    wait_for_javascript

    expect(find("#button-for-comment-#{parent_comment.id}")[:style]).to include("z-index:")
    expect(find("#button-for-comment-#{sibling_comment.id}")[:style]).to include("z-index:")
  end
end
