require "rails_helper"

RSpec.describe "Editing with an editor", type: :system do
  let!(:user) { create(:user) }
  let!(:template) { file_fixture("article_published.txt").read }
  let(:article) { create(:article, user: user, body_markdown: template) }

  before do
    sign_in user
  end

  it "user clicks the edit button", js: true, retry: 3 do
    link = "/#{user.username}/#{article.slug}"
    visit link
    find("#action-space").click
    expect(page).to have_current_path(link + "/edit")
  end

  it "user previews their changes", js: true, retry: 3 do
    visit "/#{user.username}/#{article.slug}/edit"
    fill_in "article_body_markdown", with: template.gsub("Suspendisse", "Yooo")
    click_button("PREVIEW")
    expect(page).to have_text("Yooo")
  end

  it "user updates their post", js: true, retry: 3 do
    visit "/#{user.username}/#{article.slug}/edit"
    fill_in "article_body_markdown", with: template.gsub("Suspendisse", "Yooo")
    click_button("SAVE CHANGES")
    expect(page).to have_text("Yooo")
  end

  it "user unpublishes their post", js: true, retry: 3 do
    visit "/#{user.username}/#{article.slug}/edit"
    fill_in "article_body_markdown", with: template.gsub("true", "false")
    click_button("SAVE CHANGES")
    expect(page).to have_text("Unpublished Post.")
  end
end
