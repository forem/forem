require "rails_helper"

RSpec.describe Settings::General, type: :model do
  describe "validations" do
    describe "validating URLs" do
      let(:url_fields) do
        %w[
          main_social_image logo_png mascot_image_url onboarding_background_image
        ]
      end

      it "accepts valid URLs" do
        url_fields.each do |attribute|
          expect do
            described_class.public_send("#{attribute}=", "https://example.com")
          end.not_to raise_error
        end
      end

      it "rejects invalid URLs and accepts valid ones", :aggregate_failures do
        url_fields.each do |attribute|
          expect do
            described_class.public_send("#{attribute}=", "example.com")
          end.to raise_error(/is not a valid URL/)
        end
      end
    end

    describe "validating :feed_pinned_article_id" do
      it "does not accept non numeric values" do
        expect { described_class.feed_pinned_article_id = "string" }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "does not accept ids of non existing articles" do
        expect { described_class.feed_pinned_article_id = 9999 }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "accepts nil" do
        expect { described_class.feed_pinned_article_id = nil }.not_to raise_error
      end

      it "accepts the id of an existing draft article" do
        article = create(:article, published: false)
        expect { described_class.feed_pinned_article_id = article.id }.not_to raise_error
      end

      it "accepts the id of an existing published article" do
        article = create(:article, published: true)
        expect { described_class.feed_pinned_article_id = article.id }.not_to raise_error
      end
    end
  end

  describe ".feed_pinned_article" do
    it "returns nil by default" do
      expect(described_class.feed_pinned_article).to be(nil)
    end

    it "returns nil if the pinned article is draft" do
      article = create(:article, published: false)
      allow(described_class).to receive(:feed_pinned_article_id).and_return(article.id)

      expect(described_class.feed_pinned_article).to be(nil)
    end

    it "returns the article if there is a published pinned article" do
      article = create(:article, published: true)
      allow(described_class).to receive(:feed_pinned_article_id).and_return(article.id)

      expect(described_class.feed_pinned_article.id).to eq(article.id)
    end
  end
end
