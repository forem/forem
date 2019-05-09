require "rails_helper"

RSpec.describe "Views an article", type: :system do
  let(:user) { create(:user) }
  let(:dir) { "../../support/fixtures/sample_article.txt" }
  let(:template) { File.read(File.join(File.dirname(__FILE__), dir)) }
  let!(:article) do
    create(:article, user_id: user.id, body_markdown: template.gsub("false", "true"), body_html: "")
  end
  let!(:timestamp) { "2019-03-04T10:00:00Z" }

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

  context "when showing the date" do
    before do
      article.update_column(:published_at, Time.zone.parse(timestamp))
    end

    it "shows the readable publish date" do
      visit "/#{user.username}/#{article.slug}"
      expect(page).to have_selector("article time", text: "Mar 4")
    end

    it "embeds the published timestamp" do
      visit "/#{user.username}/#{article.slug}"
      selector = "article time[datetime='#{timestamp}']"
      expect(page).to have_selector(selector)
    end
  end
end
