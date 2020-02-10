require "rails_helper"

RSpec.describe Articles::UpdateMainImageBackgroundHexWorker, type: :job do
  subject(:worker) { described_class.new }

  describe "#perform" do
    context "with article" do
      let_it_be(:article) { create(:article) }

      it "updates articles main image background hex" do
        color_from_image = double
        allow(color_from_image).to receive(:main).and_return("#eee")
        allow(ColorFromImage).to receive(:new).and_return(color_from_image)

        worker.perform(article.id)

        expect(article.reload.main_image_background_hex_color).to eql("#eee")
      end
    end

    context "without article" do
      it "does not error" do
        expect { worker.perform(nil) }.not_to raise_error
      end
    end
  end
end
