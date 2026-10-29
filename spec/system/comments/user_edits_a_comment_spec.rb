require "rails_helper"

RSpec.describe "Editing A Comment", :js do
  let(:user) { create(:user) }
  let(:article_author) { create(:user) }
  let(:article) do
    create(:article, user: article_author, show_comments: true, with_tags: false, with_main_image: false)
  end
  let(:new_comment_text) { "This is an editted text" }
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
    find("textarea").send_keys(new_comment_text)

    click_link_or_button("Submit")

    expect(page).to have_text("Edited on").and have_text(new_comment_text)

    # using .last here because the first `<time>` element is the creation date,
    # the second one is the time of editing
    timestamp = page.all(".comment-date time").last[:datetime]
    expect(timestamp).to match(iso8601_datetime_regexp)
  end

  it "opens edit from article and permalink, shows the dismiss link, and updates the comment", :aggregate_failures do
    visit article.path.to_s
    wait_for_javascript

    within("#comment-node-#{comment.id}") do
      click_on(class: "comment__dropdown-trigger")
      click_link_or_button("Edit")
    end
    expect(page).to have_text("Editing comment")
    expect(page).to have_link("Dismiss", href: comment.path)

    visit comment.path.to_s
    wait_for_javascript

    within("#comment-node-#{comment.id}") do
      click_on(class: "comment__dropdown-trigger")
      click_link_or_button("Edit")
    end
    expect(page).to have_link("Dismiss", href: comment.path)
    assert_updated
  end
end
