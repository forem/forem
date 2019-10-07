require "rails_helper"

RSpec.describe Articles::DetectHumanLanguageJob, type: :job do
  describe "#perform_now" do
    let(:article) { FactoryBot.create(:article) }

    it "updates article language with detected language" do
      detector = double
      allow(detector).to receive(:detect).and_return("en")

      described_class.perform_now(article.id)
      expect(article.language).to eql("en")
    end
  end
end
