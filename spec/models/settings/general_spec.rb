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
            described_class.public_send(:"#{attribute}=", "https://example.com")
          end.not_to raise_error
        end
      end

      it "rejects invalid URLs and accepts valid ones", :aggregate_failures do
        url_fields.each do |attribute|
          expect do
            described_class.public_send(:"#{attribute}=", "example.com")
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

    describe "validating algolia settings" do
      it "only accepts strings" do
        expect(described_class.get_setting(:algolia_application_id)[:type]).to eq(:string)
        expect(described_class.get_setting(:algolia_api_key)[:type]).to eq(:string)
        expect(described_class.get_setting(:algolia_search_only_api_key)[:type]).to eq(:string)
      end
    end

    describe "::algolia_search_enabled?" do
      it "returns true if all algolia settings are present" do
        described_class.algolia_application_id = "app_id"
        described_class.algolia_api_key = "api_key"
        described_class.algolia_search_only_api_key = "search_only_api_key"
        expect(described_class.algolia_search_enabled?).to be(true)
      end

      it "returns false if any or all of the algolia settings are missing" do
        described_class.algolia_application_id = "app_id"
        expect(described_class.algolia_search_enabled?).to be(false)
      end
    end

    describe "::set_resized_logo" do
      let(:url) { "https://example.com/logo.png" }
  
      before do
        # clear any previous settings
        described_class.set_resized_logo(nil)
        described_class.set_resized_logo_aspect_ratio(nil)
      end
  
      context "when FastImage.size returns dimensions" do
        before do
          allow(FastImage).to receive(:size).with(url).and_return([10, 8])
          described_class.set_resized_logo(url)
        end
  
        it "persists the resized_logo value" do
          expect(described_class.resized_logo).to eq(url)
        end
  
        it "computes and persists the aspect ratio as a string" do
          expect(described_class.resized_logo_aspect_ratio).to eq("10 / 8")
        end
      end
  
      context "when FastImage.size returns nil" do
        before do
          allow(FastImage).to receive(:size).with(url).and_return(nil)
        end
  
        it "does not raise, and leaves aspect_ratio unchanged" do
          expect {
            described_class.set_resized_logo(url)
          }.not_to raise_error
  
          # since we never set it, it should still be nil
          expect(described_class.resized_logo_aspect_ratio).to be_nil
        end
      end
  
      context "when FastImage.size raises an error" do
        before do
          allow(FastImage).to receive(:size).with(url).and_raise(FastImage::ImageFetchFailure)
        end
  
        it "rescues and does not raise, and leaves aspect_ratio unchanged" do
          expect {
            described_class.set_resized_logo(url)
          }.not_to raise_error
  
          expect(described_class.resized_logo_aspect_ratio).to be_nil
        end
      end
  
      context "with subforem_id" do
        let(:sub_id) { 42 }
  
        before do
          allow(FastImage).to receive(:size).with(url).and_return([20, 5])
          described_class.set_resized_logo(url, subforem_id: sub_id)
        end
  
        it "writes both values scoped to that subforem" do
          expect(described_class.resized_logo(subforem_id: sub_id)).to eq(url)
          expect(described_class.resized_logo_aspect_ratio(subforem_id: sub_id)).to eq("20 / 5")
        end
  
        it "does not affect the global (nil) subforem values" do
          expect(described_class.resized_logo(subforem_id: nil)).to be_nil
          expect(described_class.resized_logo_aspect_ratio(subforem_id: nil)).to be_nil
        end
      end
    end  
  end
end
