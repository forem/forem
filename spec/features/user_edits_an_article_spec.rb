require "rails_helper"

feature "Editing with an editor" do
  let(:user) { create(:user) }
  let(:dir) { "../support/fixtures/sample_article.txt" }
  let(:template) { File.read(File.join(File.dirname(__FILE__), dir)) }
  let(:article) do
    create(:article,
           user_id: user.id,
           body_markdown: template.gsub("false", "true"),
           body_html: "")
  end

  background do
    login_via_session_as user
  end

  scenario "user click the edit-post button", js: true, retry: 3 do
    link = "/#{user.username}/#{article.slug}"
    visit link
    find("#action-space").click
    expect(page).to have_current_path(link + "/edit")
  end

  scenario "user preview their edit post" do
    visit "/#{user.username}/#{article.slug}/edit"
    click_button("previewbutt")
    expect(page).to have_text(template[-200..-1])
  end

  scenario "user update their post" do
    visit "/#{user.username}/#{article.slug}/edit"
    fill_in "article_body_markdown", with: template.gsub("true", "false")
    click_button("article-submit")
    expect(page).to have_text("Unpublished Post.")
  end
end

