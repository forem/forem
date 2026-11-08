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

  describe ".cached_id_by_domain" do
    it "returns the id for a known domain" do
      known = create(:subforem, domain: "known.example.com")

      expect(described_class.cached_id_by_domain("known.example.com")).to eq(known.id)
    end

    it "returns nil for an unknown domain and does not query the database again" do
      expect(described_class.cached_id_by_domain("unknown.example.com")).to be_nil

      allow(described_class).to receive(:find_by).and_call_original
      expect(described_class.cached_id_by_domain("unknown.example.com")).to be_nil
      expect(described_class).not_to have_received(:find_by)
    end

    it "returns the new id once a subforem is created for a previously unknown domain" do
      expect(described_class.cached_id_by_domain("later.example.com")).to be_nil

      later = create(:subforem, domain: "later.example.com")

      expect(described_class.cached_id_by_domain("later.example.com")).to eq(later.id)
    end

    it "returns nil without querying the database for a domain containing a null byte" do
      allow(described_class).to receive(:find_by).and_call_original

      expect(described_class.cached_id_by_domain("dev.to\u0000")).to be_nil
      expect(described_class).not_to have_received(:find_by)
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

  describe ".disabled_by_env? and .multiple_subforems_enabled?" do
    let!(:default_subforem) { create(:subforem, domain: "dev.to", discoverable: true) }
    let!(:other_subforem) { create(:subforem, domain: "other.dev.to", discoverable: true) }

    before do
      MemoryFirstCache.delete("subforem_default_id")
      MemoryFirstCache.delete("subforem_discoverable_ids")
    end

    it "returns true for multiple_subforems_enabled? when > 1 discoverable subforem exists and env flags are off" do
      expect(described_class.disabled_by_env?).to be(false)
      expect(described_class.multiple_subforems_enabled?).to be(true)
    end

    it "returns false for multiple_subforems_enabled? and limits cached_discoverable_ids to default when disabled by env" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("SKIP_SUBFOREM_REASSIGNMENT").and_return("yes")

      expect(described_class.disabled_by_env?).to be(true)
      expect(described_class.multiple_subforems_enabled?).to be(false)
      expect(described_class.cached_discoverable_ids).to eq([default_subforem.id])
    end

    it "skips misc subforem queries when disabled_by_env? is true" do
      create(:subforem, misc: true, domain: "misc.dev.to")
      MemoryFirstCache.delete("subforem_misc_id")
      Rails.cache.delete("subforem_misc_object")
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("SKIP_SUBFOREM_REASSIGNMENT").and_return("yes")
      allow(described_class).to receive(:find_by).and_call_original

      expect(described_class.cached_misc_subforem_id).to be_nil
      expect(described_class.misc_subforem).to be_nil
      expect(described_class).not_to have_received(:find_by)
    end
  end

  describe "when no subforems exist" do
    before do
      described_class.destroy_all
      MemoryFirstCache.reset_memory_store!
    end

    it "negative-caches cached_default_id and short-circuits all other cached_* lookups without extra SQL queries",
       :aggregate_failures do
      expect(described_class.cached_default_id).to be_nil

      subforem_queries = []
      subscriber = lambda do |*, payload|
        subforem_queries << payload[:sql] if payload[:sql].include?("subforems") && payload[:name] != "SCHEMA"
      end

      ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
        2.times do
          expect(described_class.cached_default_id).to be_nil
          expect(described_class.cached_id_by_domain("dev.to")).to be_nil
          expect(described_class.cached_root_id).to be_nil
          expect(described_class.cached_default_domain).to be_nil
          expect(described_class.cached_root_domain).to be_nil
          expect(described_class.cached_domains).to eq([])
          expect(described_class.cached_all_domains).to eq([])
          expect(described_class.cached_id_to_domain_hash).to eq({})
          expect(described_class.cached_discoverable_ids).to eq([])
          expect(described_class.cached_postable_array).to eq([])
          expect(described_class.cached_misc_subforem_id).to be_nil
          expect(described_class.misc_subforem).to be_nil
        end
      end

      expect(subforem_queries).to be_empty
    end

    it "invalidates negative caches when a subforem is created and again when destroyed", :aggregate_failures do
      expect(described_class.cached_default_id).to be_nil
      expect(described_class.cached_default_domain).to be_nil

      created = create(:subforem, domain: "fresh.example.com", root: true, discoverable: true)

      expect(described_class.cached_default_id).to eq(created.id)
      expect(described_class.cached_default_domain).to eq("fresh.example.com")
      expect(described_class.cached_root_id).to eq(created.id)
      expect(described_class.cached_root_domain).to eq("fresh.example.com")
      expect(described_class.cached_discoverable_ids).to eq([created.id])

      created.destroy!

      expect(described_class.cached_default_id).to be_nil
      expect(described_class.cached_default_domain).to be_nil
      expect(described_class.cached_root_id).to be_nil
      expect(described_class.cached_root_domain).to be_nil
      expect(described_class.cached_discoverable_ids).to eq([])
    end
  end

  describe "negative caching when root or misc subforem does not exist" do
    before do
      create(:subforem, domain: "default.example.com", root: false, misc: false)
    end

    it "caches the absence of root and misc subforems so subsequent calls do not query the database",
       :aggregate_failures do
      expect(described_class.cached_root_id).to be_nil
      expect(described_class.cached_root_domain).to be_nil
      expect(described_class.cached_misc_subforem_id).to be_nil
      expect(described_class.misc_subforem).to be_nil

      subforem_queries = []
      subscriber = lambda do |*, payload|
        subforem_queries << payload[:sql] if payload[:sql].include?("subforems") && payload[:name] != "SCHEMA"
      end

      ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
        expect(described_class.cached_root_id).to be_nil
        expect(described_class.cached_root_domain).to be_nil
        expect(described_class.cached_misc_subforem_id).to be_nil
        expect(described_class.misc_subforem).to be_nil
      end

      expect(subforem_queries).to be_empty
    end
  end
end
