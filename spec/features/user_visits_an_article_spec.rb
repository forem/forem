require "rails_helper"

describe "Views an article" do
  let(:user) { create(:user) }
  let(:dir) { "../support/fixtures/sample_article.txt" }
  let(:template) { File.read(File.join(File.dirname(__FILE__), dir)) }
  let(:article) do
    create(:article,
           user_id: user.id,
           body_markdown: template.gsub("false", "true"),
           body_html: "")
  end

  before do
    sign_in user
  end

  it "shows an article" do
    visit "/#{user.username}/#{article.slug}"
    expect(page).to have_content(article.title)
  end

  it "shows comments", js: true, retry: 3 do
    create_list(:comment, 3, commentable: article)
    visit "/#{user.username}/#{article.slug}"
    expect(page).to have_selector(".single-comment-node", visible: true, count: 3)
  end
end
