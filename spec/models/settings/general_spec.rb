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
  end
end
