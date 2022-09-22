require "rails_helper"

RSpec.describe "Using the editor", type: :system do
  let(:user) { create(:user) }
  let(:raw_text) { "../support/fixtures/sample_article_template_spec.txt" }
  # what are these
  let(:dir) { "../support/fixtures/sample_article.txt" }
  let(:rich_dir) { "../support/fixtures/sample_rich_article.txt" }
  let(:template) { File.read(File.join(File.dirname(__FILE__), dir)) }
  let(:rich_template) { File.read(File.join(File.dirname(__FILE__), rich_dir)) }

  before do
    sign_in user
  end

  def read_from_file(dir)
    File.read(File.join(File.dirname(__FILE__), dir))
  end

  def fill_markdown_with(content)
    visit "/new"
    within("#article-form") { fill_in "article_body_markdown", with: content }
  end

  describe "Viewing the editor", js: true do
    it "renders the logo or Community name as expected" do
      visit "/new"
      expect(page).to have_css(".site-logo")
      within(".truncate-at-2") do
        expect(page).to have_text("DEV(local)")
      end
    end
  end

  describe "Previewing an article", js: true do
    before do
      fill_markdown_with(read_from_file(raw_text))
      page.execute_script("window.scrollTo(0, -100000)")
      find("button", text: /\APreview\z/).click
    end

    after do
      page.evaluate_script("window.onbeforeunload = function(){}")
    end

    it "fills out form with rich content and click preview", cloudinary: true do
      article_body = find("div.crayons-article__body")["innerHTML"]
      article_body.gsub!(%r{"https://res\.cloudinary\.com/.{1,}"}, "cloudinary_link")

      # TODO: Convert this to an E2E test?
      # rubocop:disable Style/StringLiterals
      expect(article_body).to include('<a name="multiword-heading-with-weird-punctuampation"')
        .and include('<a name="emoji-heading"')
        .and include('<blockquote>')
        .and include('Format: <a href=cloudinary_link></a>')
      # rubocop:enable Style/StringLiterals
    end
  end

  describe "Submitting an article with v1 editor", js: true do
    before { user.setting.update!(editor_version: "v1") }

    it "fill out form and submit", cloudinary: true do
      fill_markdown_with(read_from_file(raw_text))
      find("button", text: /\ASave changes\z/).click
      article_body = find(:xpath, "//div[@id='article-body']")["innerHTML"]
      article_body.gsub!(%r{"https://res\.cloudinary\.com/.{1,}"}, "cloudinary_link")

      # TODO: Convert this to an E2E test?
      # rubocop:disable Style/StringLiterals
      expect(article_body).to include('<a name="multiword-heading-with-weird-punctuampation"')
        .and include('<a name="emoji-heading"')
        .and include('<blockquote>')
        .and include('Format: <a href=cloudinary_link></a>')
      # rubocop:enable Style/StringLiterals
    end

    it "user write and publish an article" do
      fill_markdown_with(template.gsub("false", "true"))
      find("button", text: /\ASave changes\z/).click
      ["Sample Article", template[-200..], "test"].each do |text|
        expect(page).to have_text(text)
      end
    end

    context "without a title", js: true do
      before do
        fill_markdown_with(template.gsub("Sample Article", ""))
        find("button", text: /\ASave changes\z/).click
      end

      it "shows a message that the title cannot be blank" do
        expect(page).to have_text(/title: can't be blank/)
      end
    end
  end

  describe "using v2 editor", js: true do
    it "fill out form with rich content and click publish" do
      visit "/new"
      within "form#article-form" do
        fill_in "article-form-title", with: "This is a <span> test"
        find("#tag-input").native.send_keys("what", :return)
        fill_in "article_body_markdown", with: "Hello"
      end
      click_button "Publish"
      expect(page).to have_xpath("//div[@class='crayons-article__header__meta']//h1")
      expect(page).to have_text("Hello")
      expect(page).to have_link("what", href: "/t/what")
    end
  end
end
