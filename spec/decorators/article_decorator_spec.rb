require "rails_helper"

RSpec.describe ArticleDecorator, type: :decorator do
  def create_article(*args)
    article = create(:article, *args)
    article.decorate
  end

  let(:article) { build(:article) }
  let(:published_article) { create_article(published: true) }
  let(:organization) { build(:organization) }

  context "with serialization" do
    it "serializes both the decorated object IDs and decorated methods" do
      article = published_article
      expected_result = { "id" => article.id, "published_at_int" => article.published_at_int }
      expect(article.as_json(only: [:id], methods: [:published_at_int])).to eq(expected_result)
    end

    it "serializes collections of decorated objects" do
      article = published_article
      decorated_collection = Article.published.decorate
      expected_result = [{ "id" => article.id, "published_at_int" => article.published_at_int }]
      expect(decorated_collection.as_json(only: [:id], methods: [:published_at_int])).to eq(expected_result)
    end
  end

  describe "#user_data_info_to_json" do
    it "returns an escaped JSON string" do
      user = build(:user, name: '\: Hello')
      allow(article).to receive(:cached_user).and_return(user)
      decorated = article.decorate
      expect(JSON.parse(decorated.user_data_info_to_json)).to be_a(Hash)
    end
  end

  describe "#current_state_path" do
    it "returns the path /:username/:slug when published" do
      article = published_article
      expect(article.current_state_path).to eq("/#{article.username}/#{article.slug}")
    end

    it "returns the path /:username/:slug?:password when draft" do
      article = create_article(published: false)
      expected_result = "/#{article.username}/#{article.slug}?preview=#{article.password}"
      expect(article.current_state_path).to eq(expected_result)
    end

    it "returns the path /:username/:slug?:password when scheduled" do
      article = create_article(published: true, published_at: Date.tomorrow)
      expected_result = "/#{article.username}/#{article.slug}?preview=#{article.password}"
      expect(article.current_state_path).to eq(expected_result)
    end
  end

  describe "has_recent_comment_activity?" do
    it "returns false if no comment activity" do
      article.last_comment_at = nil
      expect(article.decorate.has_recent_comment_activity?).to be(false)
    end

    it "returns true if more recent than passed in value" do
      article.last_comment_at = 1.week.ago
      expect(article.decorate.has_recent_comment_activity?(2.weeks.ago)).to be(true)
    end

    it "returns false if less recent than passed in value" do
      article.last_comment_at = 4.weeks.ago
      expect(article.decorate.has_recent_comment_activity?(2.weeks.ago)).to be(false)
    end
  end

  describe "#processed_canonical_url" do
    it "strips canonical_url" do
      article.canonical_url = " http://google.com "
      expect(article.decorate.processed_canonical_url).to eq("http://google.com")
    end

    it "returns the article url without a canonical_url" do
      article.canonical_url = ""
      expected_url = "#{ApplicationConfig['APP_PROTOCOL']}#{ApplicationConfig['APP_DOMAIN']}#{article.path}"
      expect(article.decorate.processed_canonical_url).to eq(expected_url)
    end
  end

  describe "#cached_tag_list_array" do
    it "returns no tags if the cached tag list is empty" do
      article.cached_tag_list = ""
      expect(article.decorate.cached_tag_list_array).to be_empty
    end

    it "returns cached tag list as an array" do
      article.cached_tag_list = "discuss, python"
      expect(article.decorate.cached_tag_list_array).to eq(%w[discuss python])
    end
  end

  describe "#url" do
    it "returns the article url" do
      expected_url = "#{ApplicationConfig['APP_PROTOCOL']}#{ApplicationConfig['APP_DOMAIN']}#{article.path}"
      expect(article.decorate.url).to eq(expected_url)
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

  describe "#published_at_int" do
    it "returns the publication date as an integer" do
      expect(article.decorate.published_at_int).to eq(article.published_at.to_i)
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

    it "returns search_optimized_description_replacement if it is present" do
      body_markdown = "---\ntitle: Title\npublished: false\ndescription:\ntags: heytag\n---\n\nHey this is the article"
      search_optimized_description_replacement = "Hey this is the expected result"
      expect(create_article(body_markdown: body_markdown,
                            search_optimized_description_replacement: search_optimized_description_replacement)
        .description_and_tags).to eq(search_optimized_description_replacement)
    end
  end

  describe "#video_metadata" do
    it "responds with a hash representation of video metadata" do
      article_with_video = create(:article,
                                  video_code: "ABC",
                                  video_source_url: "https://cdn.com/ABC.m3u8",
                                  video_thumbnail_url: "https://cdn.com/ABC.png",
                                  video_closed_caption_track_url: "https://cdn.com/ABC_captions")

      expect(article_with_video.decorate.video_metadata).to eq(
        {
          id: article_with_video.id,
          video_code: article_with_video.video_code,
          video_source_url: article_with_video.video_source_url,
          video_thumbnail_url: article_with_video.cloudinary_video_url,
          video_closed_caption_track_url: article_with_video.video_closed_caption_track_url
        },
      )
    end
  end

  describe "#long_markdown?" do
    it "returns false if body_markdown is nil" do
      article.body_markdown = nil
      expect(article.decorate.long_markdown?).to be false
    end

    it "returns false if body_markdown has fewer characters than LONG_MARKDOWN_THRESHOLD" do
      article.body_markdown = "---\ntitle: Title\n---\n\nHey this is the article"
      expect(article.decorate.long_markdown?).to be false
    end

    it "returns true if body_markdown has more characters than LONG_MARKDOWN_THRESHOLD" do
      additional_characters_length = (ArticleDecorator::LONG_MARKDOWN_THRESHOLD + 1) - article.body_markdown.length
      article.body_markdown << Faker::Hipster.paragraph_by_chars(characters: additional_characters_length)
      expect(article.decorate.long_markdown?).to be true
    end
  end

  describe "#discussion?" do
    it "returns false if it's not tagged with discuss" do
      article.cached_tag_list = "welcome"
      expect(article.decorate.discussion?).to be false
    end

    it "returns false if published_at is less than 35 hours ago" do
      Timecop.freeze(Time.current) do
        article.published_at = 35.hours.ago - 1
        expect(article.decorate.discussion?).to be false
      end
    end

    it "returns true if it's tagged with discuss and has a published_at greater than 35 hours ago" do
      Timecop.freeze(Time.current) do
        article.cached_tag_list = "welcome, discuss"
        article.published_at = 35.hours.ago + 1
        expect(article.decorate.discussion?).to be true
      end
    end
  end

  describe "#pinned?" do
    let(:article) { create(:article) }

    it "returns false for an unsaved article" do
      article = build(:article)

      expect(article.decorate.pinned?).to be(false)
    end

    it "returns false if no article is pinned" do
      expect(article.decorate.pinned?).to be(false)
    end

    it "returns false if another article is pinned" do
      PinnedArticle.set(create(:article))

      expect(article.decorate.pinned?).to be(false)
    end

    it "returns true if the article is pinned" do
      PinnedArticle.set(article)

      expect(article.decorate.pinned?).to be(true)
    end
  end
end
