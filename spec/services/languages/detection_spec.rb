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

  context "when probability and reliability vary" do
    let(:text) { "This is some dummy text." }
    let(:identifier) { instance_double(CLD3::NNetLanguageIdentifier) }

    before do
      allow(CLD3::NNetLanguageIdentifier).to receive(:new).and_return(identifier)
      allow(identifier).to receive(:find_language).with(text).and_return(language_outcome)
    end

    context "when probability is low" do
      let(:language_outcome) do
        instance_double(
          CLD3::NNetLanguageIdentifier::Result,
          language: :es,
          probability: 0.4,
          reliable?: true
        )
      end

      it "returns nil" do
        expect(described_class.call(text)).to eq(nil)
      end
    end

    context "when reliability is low" do
      let(:language_outcome) do
        instance_double(
          'CLD3::NNetLanguageIdentifier::Result',
          language: :es,
          probability: 0.9,
          reliable?: false
        )
      end

      it "returns nil" do
        expect(described_class.call(text)).to be(nil)
      end
    end

    context "when probability and reliability are high" do
      let(:language_outcome) do
        instance_double(
          CLD3::NNetLanguageIdentifier::Result,
          language: :es,
          probability: 0.9,
          reliable?: true,
        )
      end

      it "returns es" do
        expect(described_class.call(text)).to eq(:es)
      end
    end
  end
end
