require "rails_helper"

RSpec.describe Articles::UpdateMainImageBackgroundHexJob, type: :job do
  describe "#perform_now" do
    let(:article) { FactoryBot.create(:article) }

    it "updates articles main image background hex" do
      color_from_image = double
      allow(color_from_image).to receive(:main).and_return("#eee")

      described_class.perform_now(article.id) do
        expect(article.main_image_background_hex_color).to be("#eee")
      end
    end
  end
end
