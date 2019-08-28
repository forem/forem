require "rails_helper"

RSpec.describe Articles::DetectHumanLanguageJob, type: :job do
  describe "#perform_now" do
    let(:article) { FactoryBot.create(:article) }

    it "updates article language with detected language" do
      detector = double
      allow(detector).to receive(:detect).and_return("en")

      described_class.perform_now(article.id) do
        expect(article.language).to be("en")
      end
    end

    it "does not update article language with detected language when no article is found" do
      detector = double
      allow(detector).to receive(:detect).and_return("en")

      described_class.perform_now(9999) do
        expect(article.language).not_to be("en")
      end
    end
  end
end
