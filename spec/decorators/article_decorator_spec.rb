require "rails_helper"

RSpec.describe ArticleDecorator, type: :decorator do
  def create_article(*args)
    article = create(:article, *args)
    article.decorate
  end

  let(:article) { build_stubbed(:article) }

  describe "#processed_canonical_url" do
    it "strips canonical_url" do
      article.canonical_url = " http://google.com "
      expect(article.decorate.processed_canonical_url). to eq("http://google.com")
    end

    it "returns the article url without a canonical_url" do
      article.canonical_url = ""
      expected_url = "https://#{ApplicationConfig['APP_DOMAIN']}#{article.path}"
      expect(article.decorate.processed_canonical_url).to eq(expected_url)
    end
  end

  describe "#title_length_classification" do
    it "returns article title length classifications" do
      article.title = "0" * 106
      expect(article.decorate.title_length_classification).to eq("longest")
      article.title = "0" * 81
      expect(article.decorate.title_length_classification).to eq("longer")
      article.title = "0" * 61
      expect(article.decorate.title_length_classification).to eq("long")
      article.title = "0" * 23
      expect(article.decorate.title_length_classification).to eq("medium")
      article.title = "0" * 20
      expect(article.decorate.title_length_classification).to eq("short")
    end
  end

  describe "#description_and_tags" do
    it "creates proper description when it is not present and body is present and short, and tags are present" do
      body_markdown = "---\ntitle: Title\npublished: false\ndescription:\ntags: heytag\n---\n\nHey this is the article"
      expected_result = "Hey this is the article. Tagged with heytag."
      expect(create_article(body_markdown: body_markdown).description_and_tags).to eq(expected_result)
    end

    it "creates proper description when it is not present and body is present and short, and tags are not present" do
      body_markdown = "---\ntitle: Title\npublished: false\ndescription:\ntags:\n---\n\nHey this is the article"
      expect(create_article(body_markdown: body_markdown).description_and_tags).to eq("Hey this is the article.")
    end

    it "creates proper description when it is not present and body is present and long, and tags are present" do
      paragraphs = Faker::Hipster.paragraph(sentence_count: 40)
      body_markdown = "---\ntitle: Title\npublished: false\ndescription:\ntags: heytag\n---\n\n#{paragraphs}"
      expect(create_article(body_markdown: body_markdown).description_and_tags).to end_with("... Tagged with heytag.")
    end

    it "creates proper description when it is not present and body is not present and long, and tags are present" do
      body_markdown = "---\ntitle: Title\npublished: false\ndescription:\ntags: heytag\n---\n\n"
      created_article = create_article(body_markdown: body_markdown)
      parsed_post_by_string = "A post by #{created_article.user.name}"
      parsed_post_by_string += "." unless created_article.user.name.end_with?(".")
      expect(created_article.description_and_tags).to eq("#{parsed_post_by_string} Tagged with heytag.")
    end
  end
end
