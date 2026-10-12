require "rails_helper"

RSpec.describe "Hidden comment appeal notice in the browser", :js do
  let(:author) { create(:user) }
  let(:other_reader) { create(:user) }
  let(:article) { create(:article) }
  let(:notice_selector) { ".hidden-comment-appeal-notice" }

  before do
    create(:comment, user: author, commentable: article).update_columns(score: -500)
    create(:comment, commentable: article).update_columns(score: 5)
    Comments::Count.call(article, recalculate: true)
  end

  it "shows the notice and appeal link to the comment's author" do
    sign_in author
    visit article.path

    expect(page).to have_css(notice_selector, visible: :visible, count: 1)
    expect(page).to have_link(I18n.t("views.comments.hidden_by_moderation.appeal_link"))
  end

  it "keeps the notice hidden from other signed in readers" do
    sign_in other_reader
    visit article.path

    expect(page).to have_css(notice_selector, visible: :hidden, count: 1)
    expect(page).to have_no_css(notice_selector, visible: :visible)
  end
end
