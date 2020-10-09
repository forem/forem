require "rails_helper"

RSpec.describe "Editing with an editor", type: :system, js: true do
  let(:template) { file_fixture("article_published.txt").read }
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user, body_markdown: template) }
  let(:svg_image) { file_fixture("svg_image.txt").read }

  before do
    SiteConfig.main_social_image = "https://dummyimage.com/800x600.jpg"
    SiteConfig.logo_png = "https://dummyimage.com/800x600.png"
    SiteConfig.mascot_image_url = "https://dummyimage.com/800x600.jpg"
    SiteConfig.suggested_tags = "coding, beginners"
    SiteConfig.suggested_users = "romagueramica"
    SiteConfig.logo_svg = svg_image
    sign_in user
  end

  it "user previews their changes" do
    visit "/#{user.username}/#{article.slug}/edit"
    fill_in "article_body_markdown", with: template.gsub("Suspendisse", "Yooo")
    click_button("Preview")
    expect(page).to have_text("Yooo")
  end

  it "user updates their post" do
    visit "/#{user.username}/#{article.slug}/edit"
    fill_in "article_body_markdown", with: template.gsub("Suspendisse", "Yooo")
    click_button("Save changes")
    expect(page).to have_text("Yooo")
  end

  it "user unpublishes their post" do
    visit "/#{user.username}/#{article.slug}/edit"
    fill_in "article_body_markdown", with: template.gsub("true", "false")
    click_button("Save changes")
    expect(page).to have_text("Unpublished Post.")
  end
end
