require "rails_helper"

RSpec.describe "Editing with an editor", type: :system, js: true do
  let_it_be(:template) { file_fixture("article_published.txt").read }
  let_it_be(:user) { create(:user) }
  let_it_be(:article, reload: true) { create(:article, user: user, body_markdown: template) }

  before do
    sign_in user
  end

  it "user previews their changes" do
    visit "/#{user.username}/#{article.slug}/edit"
    fill_in "article_body_markdown", with: template.gsub("Suspendisse", "Yooo")
    click_button("PREVIEW")
    expect(page).to have_text("Yooo")
    expect(find(".active").text).to have_text("EDIT")
  end

  it "user updates their post" do
    visit "/#{user.username}/#{article.slug}/edit"
    fill_in "article_body_markdown", with: template.gsub("Suspendisse", "Yooo")
    click_button("SAVE CHANGES")
    expect(page).to have_text("Yooo")
  end

  it "user unpublishes their post" do
    visit "/#{user.username}/#{article.slug}/edit"
    fill_in "article_body_markdown", with: template.gsub("true", "false")
    click_button("SAVE CHANGES")
    expect(page).to have_text("Unpublished Post.")
  end
end
