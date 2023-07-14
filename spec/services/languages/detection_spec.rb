require "rails_helper"

RSpec.describe Languages::Detection, type: :service do
  subject(:language_detection) { described_class.call(text) }

  context "when the text is clearly identifiable as English" do
    let(:text) { "This is clearly English text." }

    it "returns en" do
      expect(language_detection).to eq(:en)
    end
  end

  context "when the text is clearly identifiable as Spanish" do
    let(:text) { "Esto es claramente un texto en español." }

    it "returns es" do
      expect(language_detection).to eq(:es)
    end
  end
end
