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
    let(:cover) { "https://example.com/cover.png" }
    let(:video_thumbnail) { "https://image.mux.com/abc123/thumbnail.webp" }
    let(:generated_card) { "https://example.com/generated.png" }

    before do
      allow(Images::Optimizer).to receive(:call) { |image, **_options| "optimized:#{image}" }
    end

    it "prefers the cover image over the video thumbnail and the generated card" do
      article.update_columns(main_image: cover, video_thumbnail_url: video_thumbnail, social_image: generated_card)
      expect(described_class.new(article).url).to eq("optimized:#{cover}")
    end

    it "uses the video thumbnail instead of the generated card" do
      article.update_columns(main_image: nil, video_thumbnail_url: video_thumbnail, social_image: generated_card)
      expect(described_class.new(article).url).to eq("optimized:#{video_thumbnail}")
    end

    it "uses the generated card when there is no cover or video" do
      article.update_columns(main_image: nil, video_thumbnail_url: nil, social_image: generated_card)
      expect(described_class.new(article).url).to eq("optimized:#{generated_card}")
    end

    it "falls back to the community's default social image" do
      allow(Settings::General).to receive(:main_social_image).and_return("https://example.com/default.png")
      article.update_columns(main_image: nil, video_thumbnail_url: nil, social_image: nil)
      expect(described_class.new(article).url).to eq("https://example.com/default.png")
    end
  end
end
