require "rails_helper"

feature "Using the editor" do
  let(:user) { create(:user) }
  let(:raw_text) { "../support/fixtures/sample_article_template_spec.txt" }
  # what are these
  let(:dir) { "../support/fixtures/sample_article.txt" }
  let(:rich_dir) { "../support/fixtures/sample_rich_article.txt" }
  let(:template) { File.read(File.join(File.dirname(__FILE__), dir)) }
  let(:rich_template) { File.read(File.join(File.dirname(__FILE__), rich_dir)) }

  background do
    sign_in user
  end

  def read_from_file(dir)
    File.read(File.join(File.dirname(__FILE__), dir))
  end

  def fill_markdown_with(content)
    visit "/new"
    fill_in "article_body_markdown", with: content
  end

  feature "Previewing an article", js: true do
    after do
      page.evaluate_script("window.onbeforeunload = function(){}")
    end

    scenario "fill out form with ruch content and click preview" do
      fill_markdown_with(read_from_file(raw_text))
      page.execute_script("window.scrollTo(0, -100000)")
      find("button#previewbutt").click
      article_body = find(:xpath, "//div[@id='article_body']")["innerHTML"]
      Approvals.verify(article_body, name: "user_preview_article_body", format: :html)
    end
  end

  feature "Submitting an article" do
    scenario "fill out form and submit" do
      fill_markdown_with(read_from_file(raw_text))
      click_button("article-submit")
      article_body = find(:xpath, "//div[@id='article-body']")["innerHTML"]
      Approvals.verify(article_body, name: "user_submit_article", format: :html)
    end

    scenario "user write and publish an article" do
      fill_markdown_with(template.gsub("false", "true"))
      click_button("article-submit")
      ["Sample Article", template[-200..-1], "test"].each do |text|
        expect(page).to have_text(text)
      end
    end

    scenario "user write and publish an article without a title" do
      fill_markdown_with(template.gsub("Sample Article", ""))
      click_button("article-submit")
      expect(page).to have_css("div#error_explanation",
                               text: "Title can't be blank")
    end
  end
end
