require "rails_helper"

RSpec.describe "Editing A Comment", type: :system, js: true do
  let(:user) { create(:user) }
  let!(:article) { create(:article, show_comments: true) }
  let(:new_comment_text) { Faker::Lorem.paragraph }
  let!(:comment) do
    create(:comment,
           commentable: article,
           user: user,
           body_markdown: Faker::Lorem.paragraph)
  end
  let(:iso8601_datetime_regexp) { /^((\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})Z)$/ }

  before do
    sign_in user
  end

  def assert_updated
    expect(page).to have_css("textarea")
    expect(page).to have_text("Editing comment")
    fill_in "text-area", with: new_comment_text

    click_button("Submit")

    expect(page).to have_text(new_comment_text)

    expect(page).to have_text("Edited on")
    # using .last here because the first `<time>` element is the creation date,
    # the second one is the time of editing
    timestamp = page.all(".comment-date time").last[:datetime]
    expect(timestamp).to match(iso8601_datetime_regexp)
  end

  context "when user edits comment on the bottom of the article" do
    it "updates" do
      visit article.path.to_s
      wait_for_javascript

      click_on(class: "comment__dropdown-trigger")
      click_link("Edit")
      assert_updated
    end
  end

  context "when user edits via permalinks" do
    it "updates" do
      user.reload

      visit user.comments.last.path.to_s

      wait_for_javascript

      click_on(class: "comment__dropdown-trigger")
      click_link("Edit")
      assert_updated
    end
  end

  context "when user edits via direct path (no referer)" do
    it "cancels to the article page" do
      user.reload
      visit "#{comment.path}/edit"
      expect(page).to have_link("Dismiss")
    end
  end
end
