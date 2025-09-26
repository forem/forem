require "rails_helper"

RSpec.describe Subforem do
  let(:subforem) { create(:subforem) }

  before do
    allow(Subforems::CreateFromScratchWorker).to receive(:perform_async)
  end

  describe "validations" do
    it "calls subforem_default_idods after save" do
      expect(subforem).to receive(:bust_caches)
      subforem.save!
    end

    it "downcases domain before validation" do
      subforem.domain = "EXAMPLE.COM"
      subforem.valid?
      expect(subforem.domain).to eq("example.com")
    end

    it "calculates score and hotness_score correctly" do
      # Create some articles with scores
      create(:article, :past, subforem: subforem, score: 10)
      create(:article, :past, subforem: subforem, score: 20)
      create(:article, :past, subforem: subforem, score: 30)

      subforem.update_scores!

      expect(subforem.score).to be > 0
      expect(subforem.hotness_score).to be > 0
    end
  end

  describe "misc subforem functionality" do
    it "finds misc subforem" do
      misc_subforem = create(:subforem, misc: true, domain: "misc.example.com")
      regular_subforem = create(:subforem, misc: false, domain: "regular.example.com")

      expect(Subforem.misc_subforem).to eq(misc_subforem)
      expect(Subforem.cached_misc_subforem_id).to eq(misc_subforem.id)
    end

    it "returns nil when no misc subforem exists" do
      create(:subforem, misc: false, domain: "regular.example.com")

      expect(Subforem.misc_subforem).to be_nil
      expect(Subforem.cached_misc_subforem_id).to be_nil
    end

    it "busts misc subforem cache when subforem is updated" do
      misc_subforem = create(:subforem, misc: true, domain: "misc.example.com")

      # Verify cache is populated
      expect(Subforem.cached_misc_subforem_id).to eq(misc_subforem.id)

      # Update the subforem
      misc_subforem.update!(domain: "updated.example.com")

      # Cache should be busted and repopulated
      expect(Subforem.cached_misc_subforem_id).to eq(misc_subforem.id)
    end
  end

  describe ".create_from_scratch!" do
    let(:domain) { "test.com" }
    let(:brain_dump) { "A test community" }
    let(:name) { "Test Community" }
    let(:logo_url) { "https://example.com/logo.png" }
    let(:bg_image_url) { "https://example.com/background.jpg" }

    it "creates a subforem and queues background job" do
      expect do
        described_class.create_from_scratch!(
          domain: domain,
          brain_dump: brain_dump,
          name: name,
          logo_url: logo_url,
          bg_image_url: bg_image_url,
        )
      end.to change(Subforem, :count).by(1)

      subforem = Subforem.last
      expect(subforem.domain).to eq(domain)

      expect(Subforems::CreateFromScratchWorker).to have_received(:perform_async).with(
        subforem.id,
        brain_dump,
        name,
        logo_url,
        bg_image_url,
        "en",
      )
    end

    it "works without background image URL" do
      expect do
        described_class.create_from_scratch!(
          domain: domain,
          brain_dump: brain_dump,
          name: name,
          logo_url: logo_url,
        )
      end.to change(Subforem, :count).by(1)

      subforem = Subforem.last
      expect(Subforems::CreateFromScratchWorker).to have_received(:perform_async).with(
        subforem.id,
        brain_dump,
        name,
        logo_url,
        nil,
        "en",
      )
    end

    it "returns the created subforem" do
      result = described_class.create_from_scratch!(
        domain: domain,
        brain_dump: brain_dump,
        name: name,
        logo_url: logo_url,
      )

      expect(result).to be_a(Subforem)
      expect(result.domain).to eq(domain)
    end
  end
end
