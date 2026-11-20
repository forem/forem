require "rails_helper"

RSpec.describe "Using the editor" do
  let(:user) { create(:user, profile_image: nil) }
  let(:raw_text) { "../support/fixtures/sample_article_template_spec.txt" }
  let(:dir) { "../support/fixtures/sample_article.txt" }
  let(:template) { File.read(File.join(File.dirname(__FILE__), dir)) }

  before do
    sign_in user
  end

  def read_from_file(dir)
    File.read(File.join(File.dirname(__FILE__), dir))
  end

  def fill_markdown_with(content)
    visit "/new"
    expect(page).to have_css("body[data-loaded='true']")
    within("#article-form") { fill_in "article_body_markdown", with: content }
  end

  describe "Submitting an article with v1 editor", :js do
    before { user.setting.update!(editor_version: "v1") }

    it "previews and submits an article with rich content", :aggregate_failures, :cloudinary do
      fill_markdown_with(read_from_file(raw_text))
      page.execute_script("window.scrollTo(0, -100000)")
      click_on "Preview"

      preview_body = find("div.crayons-article__body")["innerHTML"]
      preview_body.gsub!(%r{"https://res\.cloudinary\.com/.{1,}"}, "cloudinary_link")

      # TODO: Convert this to an E2E test?
      # rubocop:disable Style/StringLiterals
      expect(preview_body).to include('<a name="multiword-heading-with-weird-punctuampation"')
        .and include('<a name="emoji-heading"')
        .and include('<blockquote>')
        .and include('Format: <a href=cloudinary_link></a>')

      click_on "Save changes"
      article_body = find(:xpath, "//div[@id='article-body']")["innerHTML"]
      article_body.gsub!(%r{"https://res\.cloudinary\.com/.{1,}"}, "cloudinary_link")

      expect(article_body).to include('<a name="multiword-heading-with-weird-punctuampation"')
        .and include('<a name="emoji-heading"')
        .and include('<blockquote>')
        .and include('Format: <a href=cloudinary_link></a>')
      # rubocop:enable Style/StringLiterals
    end

    it "shows a blank-title error and publishes once a valid title is provided", :aggregate_failures do
      fill_markdown_with(template.gsub("Sample Article", ""))
      click_on "Save changes"
      expect(page).to have_text(/title: can't be blank/)

      within("#article-form") { fill_in "article_body_markdown", with: template.gsub("false", "true") }
      click_on "Save changes"
      expect(page).to have_text("Sample Article")
      expect(page).to have_text("Suspendisse ac lobortis velit")
      expect(page).to have_text("test")
    end
  end

  describe "using v2 editor", :js do
    it "renders community branding, toggles the AI Editor Buddy, and publishes an article", :aggregate_failures do
      stub_const("AI_AVAILABLE", true)
      visit "/new"
      expect(page).to have_css("body[data-loaded='true']")

      expect(page).to have_css(".site-logo")
      within(".truncate-at-2") do
        expect(page).to have_text("DEV(local)")
      end

      expect(page).to have_css("#editor-ai-toggle-btn")
      find_by_id("editor-ai-toggle-btn").click

      expect(page).to have_css("#editor-sidecar.editor-sidecar--open", visible: :visible)

      within("#editor-sidecar") do
        # Assert community name is natively interpolated from the Settings table.
        community_name = Settings::Community.community_name
        expect(page).to have_text("#{community_name} Buddy")
        expect(page).to have_text("Hello! I am your writing assistant. I know #{community_name} Editor guidelines.")
        expect(page).to have_text("advice on community guidelines and expectations?")
      end

      find_by_id("editor-ai-close-btn").click

      within "form#article-form" do
        fill_in "article-form-title", with: "This is a <span> test"
        find_by_id("tag-input").native.send_keys("what", :return)
        fill_in "article_body_markdown", with: "Hello"
      end
      click_on "Publish"
      expect(page).to have_xpath("//div[@class='crayons-article__header__meta']//h1")
      expect(page).to have_text("Hello")
      expect(page).to have_link("what", href: "/t/what")
    end
  end
end
