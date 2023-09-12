require "rails_helper"

RSpec.describe Settings::General do
  describe "validations" do
    describe "validating URLs" do
      let(:url_fields) do
        %w[
          main_social_image logo_png mascot_image_url
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

      it "does not accept the id of an existing draft article" do
        article = create(:article, published: false)
        expect { described_class.feed_pinned_article_id = article.id }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "accepts the id of an existing published article" do
        article = create(:article, published: true)
        expect { described_class.feed_pinned_article_id = article.id }.not_to raise_error
      end
    end

    describe "validating :default_content_language" do
      it "does not accept languages that are not included" do
        expect { described_class.default_content_language = "hahaha" }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "accepts languages that are included" do
        expect { described_class.default_content_language = "ru" }.not_to raise_error
      end
    end

    describe "validating :billboard_enabled_countries" do
      it "does not accept non-hash or empty values" do
        expect { described_class.billboard_enabled_countries = "string" }.to raise_error(ActiveRecord::RecordInvalid)
        expect { described_class.billboard_enabled_countries = [] }.to raise_error(ActiveRecord::RecordInvalid)
        expect { described_class.billboard_enabled_countries = {} }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "accepts any valid ISO 3166-2 codes as keys" do
        countries = ISO3166::Country.codes.sample(5).index_with { :with_regions }

        expect { described_class.billboard_enabled_countries = countries }.not_to raise_error
      end

      it "does not accept invalid ISO 3166-2 codes as keys" do
        countries = { "XX" => :with_regions, "ZZ" => :with_regions }

        expect { described_class.billboard_enabled_countries = countries }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "allows 'with_regions' and 'without_regions' marker as values to enable/disable region targeting" do
        countries = { "CA" => :with_regions, "ZA" => :with_regions, "GB" => :without_regions }

        expect { described_class.billboard_enabled_countries = countries }.not_to raise_error
      end

      it "does not allow arbitrary strings or symbols as values" do
        countries = { "CA" => :with_regions, "US" => "string" }
        other_countries = { "CA" => :with_regions, "US" => :string }

        expect { described_class.billboard_enabled_countries = countries }.to raise_error(ActiveRecord::RecordInvalid)
        expect do
          described_class.billboard_enabled_countries = other_countries
        end.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
