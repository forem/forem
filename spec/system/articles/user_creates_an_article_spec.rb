require "rails_helper"

RSpec.describe "Creating an article with the editor" do
  include_context "with legacy code tag"

  let(:user) do
    u = create(:user)
    u.setting.update(editor_version: "v1")
    u
  end
  let(:template) { file_fixture("article_published.txt").read }
  let(:template_with_legacy_code_tag) do
    file_fixture("article_with_legacy_code_tag.txt").read
  end
  let(:template_with_legacy_code_tag_with_preamble) do
    file_fixture("article_with_legacy_code_tag_with_preamble.txt").read
  end

  before do
    sign_in user
  end

  it "creates a new article and hides active announcement broadcasts on /new", :aggregate_failures, :flaky, :js do
    create(:announcement_broadcast)
    visit new_path
    expect(page).to have_css("body[data-loaded='true']")
    expect(page).to have_no_css(".broadcast-wrapper .broadcast-data")

    fill_in "article_body_markdown", with: template
    click_on "Save changes"
    expect(page).to have_css("header h1", text: "Sample Article")
  end

  context "with legacy code tag", :js do
    # These are skipped because the legacy code tag consistency is not a priority
    it "creates a new article with a legacy code tag", skip: "legacy code tag consistency is not a priority" do
      visit new_path
      fill_in "article_body_markdown", with: template_with_legacy_code_tag
      click_on "Save changes"

      expect(page).to have_no_current_path(new_path)
      expect_legacy_code_tag_to_be_visible
    end

    it "creates a new article with a legacy code tag with complex preamble",
       skip: "legacy code tag consistency is not a priority" do
      visit new_path
      fill_in "article_body_markdown", with: template_with_legacy_code_tag_with_preamble
      click_on "Save changes"

      expect(page).to have_no_current_path(new_path)
      expect_legacy_code_tag_to_be_visible(count: 2)
    end

    # TODO: [@forem/sre] figure out why this fails intermittently :-|
    it "previews article with a legacy code tag and creates it", skip: "fails intermittently" do
      visit new_path
      fill_in "article_body_markdown", with: template_with_legacy_code_tag
      click_on "Preview"

      expect_legacy_code_tag_to_be_visible

      click_on "Edit"

      expect_no_legacy_code_tag_to_be_visible

      click_on "Save changes"

      expect_legacy_code_tag_to_be_visible
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

    it "displays a rate limit warning", :flaky, :js do
      visit new_path
      expect(page).to have_css("body[data-loaded='true']")
      fill_in "article_body_markdown", with: template
      click_on "Save changes"
      expect(page).to have_text("Rate limit reached")
    end
  end
end
