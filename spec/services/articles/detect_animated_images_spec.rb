require "rails_helper"

RSpec.describe Articles::DetectAnimatedImages, type: :service do
  let(:article) { create(:article) }

  def assert_unchanged(article)
    previous_html = article.processed_html
    described_class.call(article)
    expect(article.reload.processed_html).to eq(previous_html)
  end

  def assert_has_data_animated_attribute(article, count = 1)
    described_class.call(article)

    parsed_html = Nokogiri::HTML.fragment(article.processed_html)
    expect(parsed_html.css("img[data-animated]").count).to eq(count)
  end

  context "when the body has no images" do
    it "does not alter the processed HTML" do
      assert_unchanged(article)
    end
  end

  context "when the body renders a liquid tag with images" do
    it "does not alter the processed HTML using CommentTag" do
      comment = create(:comment)
      article.update(body_markdown: "{% comment #{comment.id_code} %}")

      assert_unchanged(article)
    end

    it "does not alter the processed HTML using Github::GitHubIssueTag",
       vcr: { cassette_name: "github_client_issue" } do
      article.update(body_markdown: "{% github https://github.com/thepracticaldev/dev.to/issues/7434 %}")

      assert_unchanged(article)
    end

    it "does not alter the processed HTML using Github::GithubReadmeTag",
       vcr: { cassette_name: "github_client_repository" } do
      article.update(body_markdown: "{% github https://github.com/rust-lang/rust %}")

      assert_unchanged(article)
    end

    it "does not alter the processed HTML using MediumTag", vcr: { cassette_name: "medium" } do
      url = "https://medium.com/@edisonywh/my-ruby-journey-hooking-things-up-91d757e1c59c"
      article.update(body_markdown: "{% medium #{url} %}")

      assert_unchanged(article)
    end

    it "does not alter the processed HTML using LinkTag" do
      article.update(body_markdown: "{% link #{article.path} %}")

      assert_unchanged(article)
    end

    it "does not alter the processed HTML using OrganizationTag" do
      organization = create(:organization)
      article.update(body_markdown: "{% organization #{organization.slug} %}")

      assert_unchanged(article)
    end

    it "does not alter the processed HTML using PodcastTag" do
      podcast_episode = create(:podcast_episode)
      article.update(body_markdown: "{% podcast #{podcast_episode.path} %}")

      assert_unchanged(article)
    end

    it "does not alter the processed HTML using RedditTag", vcr: { cassette_name: "reddit_liquid_tag" } do
      url = "https://www.reddit.com/r/IAmA/comments/afvl2w/im_scott_from_scotts_cheap_flights_my_profession"
      article.update(body_markdown: "{% reddit #{url} %}")

      assert_unchanged(article)
    end

    it "does not alter the processed HTML using StackexchangeTag",
       vcr: { cassette_name: "stackexchange_tag_stackoverflow" } do
      article.update(body_markdown: "{% stackoverflow 57496168 %}")

      assert_unchanged(article)
    end

    it "does not alter the processed HTML using TweetTag",
       vcr: { cassette_name: "twitter_client_status_extended" } do
      article.update(body_markdown: "{% twitter 1018911886862057472 %}")

      assert_unchanged(article)
    end

    it "does not alter the processed HTML using UserSubscriptionTag" do
      article = create(:article, :with_user_subscription_tag_role_user, with_user_subscription_tag: true)

      assert_unchanged(article)
    end

    it "does not alter the processed HTML using UserTag" do
      article.update(body_markdown: "{% user #{article.user.username} %}")

      assert_unchanged(article)
    end
  end

  context "when the body contains uploaded images" do
    let(:uploader) { ArticleImageUploader.new }
    let(:static_image) do
      Rack::Test::UploadedFile.new(
        Rails.root.join("spec/support/fixtures/images/image1.jpeg"),
        "image/jpeg",
      )
    end
    let(:animated_image) do
      Rack::Test::UploadedFile.new(
        Rails.root.join("spec/support/fixtures/images/image.gif"),
        "image/gif",
      )
    end

    it "does not set data-animated to true with a static image" do
      uploader.store!(static_image)

      article.update(body_markdown: "![image](#{uploader.url})")

      assert_unchanged(article)
    end

    it "sets data-animated to true with an animated image" do
      uploader.store!(animated_image)

      article.update(body_markdown: "![image](#{uploader.url})")

      assert_has_data_animated_attribute(article)
    end

    it "works with multiple animated images" do
      urls = Array.new(2) do
        uploader.store!(animated_image)
        uploader.url
      end

      article.update(body_markdown: "![image](#{urls.first}) ![image](#{urls.second})")

      assert_has_data_animated_attribute(article, urls.count)
    end

    it "works with static images mixed with animated images" do
      urls = []

      uploader.store!(static_image)
      urls << uploader.url

      uploader.store!(animated_image)
      urls << uploader.url

      article.update(body_markdown: "![image](#{urls.first}) ![image](#{urls.second})")

      assert_has_data_animated_attribute(article, 1)
    end
  end

  context "when the body contains remote images" do
    let(:static_image_url) { "https://dummyimage.com/600.jpg" }
    let(:animated_image_url) { "https://i.giphy.com/media/kHTMgZ3PeK6wJsqy2s/source.gif" }

    it "does not set data-animated to true with a static image" do
      article.update(body_markdown: "![image](#{static_image_url})")

      assert_unchanged(article)
    end

    it "sets data-animated to true with an animated image", vcr: { cassette_name: "download_animated_image" } do
      article.update(body_markdown: "![image](#{animated_image_url})")

      assert_has_data_animated_attribute(article)
    end

    it "works with multiple animated images", vcr: { cassette_name: "download_animated_images_twice" } do
      article.update(body_markdown: "![image](#{animated_image_url}) ![image](#{animated_image_url})")

      assert_has_data_animated_attribute(article, 2)
    end

    it "works with static images mixed with animated images", vcr: { cassette_name: "download_animated_image" } do
      article.update(body_markdown: "![image](#{static_image_url}) ![image](#{animated_image_url})")

      assert_has_data_animated_attribute(article, 1)
    end
  end
end
