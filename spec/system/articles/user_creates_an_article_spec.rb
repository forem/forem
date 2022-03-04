require "rails_helper"

RSpec.describe "Creating an article with the editor", type: :system do
  include_context "with runkit_tag"

  let(:user) do
    u = create(:user)
    u.setting.update(editor_version: "v1")
    u
  end
  let!(:template) { file_fixture("article_published.txt").read }
  let!(:template_with_runkit_tag) do
    file_fixture("article_with_runkit_tag.txt").read
  end
  let!(:template_with_runkit_tag_with_preamble) do
    file_fixture("article_with_runkit_tag_with_preamble.txt").read
  end

  before do
    sign_in user
  end

  it "creates a new article", :flaky, js: true do
    visit new_path
    fill_in "article_body_markdown", with: template
    click_button "Save changes"
    expect(page).to have_selector("header h1", text: "Sample Article")
  end

  context "with an active announcement" do
    before do
      create(:announcement_broadcast)
      get "/async_info/base_data" # Explicitly ensure broadcast data is loaded before doing any checks
      visit new_path
    end

    it "does not render the announcement broadcast", js: true do
      expect(page).not_to have_css(".broadcast-wrapper")
      expect(page).not_to have_selector(".broadcast-data")
      expect(page).not_to have_text("Hello, World!")
    end
  end

  context "with Runkit tag", js: true do
    it "creates a new article with a Runkit tag" do
      visit new_path
      fill_in "article_body_markdown", with: ""
      fill_in "article_body_markdown", with: template_with_runkit_tag
      click_button "Save changes"

      expect_runkit_tag_to_be_active
    end

    it "creates a new article with a Runkit tag with complex preamble" do
      visit new_path
      fill_in "article_body_markdown", with: ""
      fill_in "article_body_markdown", with: template_with_runkit_tag_with_preamble
      click_button "Save changes"

      expect_runkit_tag_to_be_active(count: 2)
    end

    # TODO: [@forem/sre] figure out why this fails intermittently :-|
    xit "previews article with a Runkit tag and creates it" do
      visit new_path
      fill_in "article_body_markdown", with: template_with_runkit_tag
      click_button "Preview"

      expect_runkit_tag_to_be_active

      click_button "Edit"

      expect_no_runkit_tag_to_be_active

      click_button "Save changes"

      expect_runkit_tag_to_be_active
    end
  end

  context "when user creates too many articles" do
    let(:rate_limit_checker) { RateLimitChecker.new(user) }

    before do
      # avoid hitting new user rate limit check
      allow(user).to receive(:created_at).and_return(1.week.ago)
      allow(RateLimitChecker).to receive(:new).and_return(rate_limit_checker)
      allow(rate_limit_checker).to receive(:limit_by_action)
        .with(:published_article_creation)
        .and_return(true)
    end

    it "displays a rate limit warning", :flaky, js: true do
      visit new_path
      fill_in "article_body_markdown", with: template
      click_button "Save changes"
      expect(page).to have_text("Rate limit reached")
    end
  end
end
