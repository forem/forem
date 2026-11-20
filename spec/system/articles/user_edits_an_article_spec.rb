require "rails_helper"

RSpec.describe "Editing with an editor", :js do
  let(:template) { file_fixture("article_published.txt").read }
  let(:user) { create(:user, profile_image: nil) }
  let(:article) { create(:article, user: user, body_markdown: template, with_tags: false, with_main_image: false) }

  before do
    allow(Settings::General).to receive_messages(
      main_social_image: "https://dummyimage.com/800x600.jpg",
      logo_png: "https://dummyimage.com/800x600.png",
      mascot_image_url: "https://dummyimage.com/800x600.jpg",
      suggested_tags: "coding, beginners",
    )
    sign_in user
  end

  it "user previews their changes and updates their post", :aggregate_failures do
    visit "/#{user.username}/#{article.slug}/edit"
    expect(page).to have_css("body[data-loaded='true']")
    fill_in "article_body_markdown", with: template.gsub("Suspendisse", "Yooo")

    click_on("Preview")
    expect(page).to have_css(".crayons-article__body", text: "Yooo")

    click_on("Save changes")
    expect(page).to have_css("#article-body", text: "Yooo")
  end

  it "user unpublishes their post" do
    visit "/#{user.username}/#{article.slug}/edit"
    expect(page).to have_css("body[data-loaded='true']")
    fill_in "article_body_markdown", with: template.gsub("true", "false")
    click_on("Save changes")
    expect(page).to have_text("Unpublished Post.")
  end

  context "when user edits too many articles" do
    let(:rate_limit_checker) { RateLimitChecker.new(user) }

    before do
      # avoid hitting new user rate limit check
      allow(user).to receive(:created_at).and_return(1.week.ago)
      allow(RateLimitChecker).to receive(:new).and_return(rate_limit_checker)
      allow(rate_limit_checker).to receive(:limit_by_action)
        .with(:article_update)
        .and_return(true)
    end

    it "displays a rate limit warning", :flaky, :js do
      visit "/#{user.username}/#{article.slug}/edit"
      expect(page).to have_css("body[data-loaded='true']")
      click_on "Save changes"
      expect(page).to have_text("Rate limit reached")
    end
  end
end
