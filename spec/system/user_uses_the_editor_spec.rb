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
    fill_in "article_body_markdown", with: content
  end

  describe "Previewing an article", js: true do
    after do
      page.evaluate_script("window.onbeforeunload = function(){}")
    end

    it "fill out form with rich content and click preview" do
      fill_markdown_with(read_from_file(raw_text))
      page.execute_script("window.scrollTo(0, -100000)")
      find("button", text: /\APREVIEW\z/).click
      article_body = find("div.body")["innerHTML"]
      article_body.gsub!(/"https:\/\/res\.cloudinary\.com\/.{1,}"/, "cloudinary_link")
      Approvals.verify(article_body, name: "user_preview_article_body", format: :html)
    end
  end

  describe "Submitting an article", js: true do
    it "fill out form and submit" do
      fill_markdown_with(read_from_file(raw_text))
      find("button", text: /\ASAVE CHANGES\z/).click
      article_body = find(:xpath, "//div[@id='article-body']")["innerHTML"]
      article_body.gsub!(/"https:\/\/res\.cloudinary\.com\/.{1,}"/, "cloudinary_link")
      Approvals.verify(article_body, name: "user_preview_article_body", format: :html)
    end

    it "user write and publish an article" do
      fill_markdown_with(template.gsub("false", "true"))
      find("button", text: /\ASAVE CHANGES\z/).click
      ["Sample Article", template[-200..-1], "test"].each do |text|
        expect(page).to have_text(text)
      end
    end

    it "user write and publish an article without a title" do
      fill_markdown_with(template.gsub("Sample Article", ""))
      find("button", text: /\ASAVE CHANGES\z/).click
      expect(page).to have_text(/title:  can't be blank/)
    end
  end
end
