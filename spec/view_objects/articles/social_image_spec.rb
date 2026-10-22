require "rails_helper"

RSpec.describe Articles::SocialImage do
  let(:article) { create(:article) }

  describe "#initialize" do
    context "when height and width are not provided" do
      context "when article is published before March 1 2026" do
        before do
          article.published_at = Time.zone.local(2026, 2, 28)
        end

        it "defaults to 1000x500" do
          social_image = described_class.new(article)
          expect(social_image.send(:width)).to eq(1000)
          expect(social_image.send(:height)).to eq(500)
        end
      end

      context "when article is published after March 1 2026" do
        before do
          article.published_at = Time.zone.local(2026, 3, 2)
        end

        it "defaults to 1200x627" do
          social_image = described_class.new(article)
          expect(social_image.send(:width)).to eq(1200)
          expect(social_image.send(:height)).to eq(627)
        end
      end

      context "when article is not published" do
        before do
          article.published_at = nil
        end

        it "defaults to 1000x500" do
          social_image = described_class.new(article)
          expect(social_image.send(:width)).to eq(1000)
          expect(social_image.send(:height)).to eq(500)
        end
      end
    end

    context "when height and width are explicitly provided" do
      it "uses the provided dimensions" do
        social_image = described_class.new(article, width: 800, height: 400)
        expect(social_image.send(:width)).to eq(800)
        expect(social_image.send(:height)).to eq(400)
      end
    end
  end

  describe "#url" do
    let(:article) { create(:article, with_main_image: false) }
    let(:social_image) { "https://example.com/social.png" }
    let(:twitter_image) { "https://example.com/twitter.png" }

    before do
      allow(Images::Optimizer).to receive(:call) { |image, **_options| "optimized:#{image}" }
      article.update_columns(social_image: social_image, twitter_social_image: twitter_image)
    end

    it "uses the generated social image by default" do
      expect(described_class.new(article).url).to eq("optimized:#{social_image}")
    end

    it "uses the X-specific generated image when twitter: true" do
      expect(described_class.new(article, twitter: true).url).to eq("optimized:#{twitter_image}")
    end

    it "falls back to the generated social image when the X image is missing" do
      article.update_columns(twitter_social_image: nil)
      expect(described_class.new(article, twitter: true).url).to eq("optimized:#{social_image}")
    end

    it "prefers the cover image over both generated images" do
      article.update_columns(main_image: "https://example.com/cover.png")
      expect(described_class.new(article, twitter: true).url).to eq("optimized:https://example.com/cover.png")
    end
  end
end
