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
end
