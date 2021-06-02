require "rails_helper"

RSpec.describe "Editing with an editor", type: :system, js: true do
  let(:template) { file_fixture("article_published.txt").read }
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user, body_markdown: template) }
  let(:svg_image) { file_fixture("300x100.svg").read }

  before do
    allow(Settings::General).to receive(:main_social_image).and_return("https://dummyimage.com/800x600.jpg")
    allow(Settings::General).to receive(:logo_png).and_return("https://dummyimage.com/800x600.png")
    allow(Settings::General).to receive(:mascot_image_url).and_return("https://dummyimage.com/800x600.jpg")
    allow(Settings::General).to receive(:suggested_tags).and_return("coding, beginners")
    allow(Settings::General).to receive(:suggested_users).and_return("romagueramica")
    allow(Settings::General).to receive(:logo_svg).and_return(svg_image)
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
    fill_in("article_body_markdown", with: template.gsub("true", "false"), fill_options: { clear: :backspace })
    click_button("Save changes")
    expect(page).to have_text("Unpublished Post.")
  end
end
