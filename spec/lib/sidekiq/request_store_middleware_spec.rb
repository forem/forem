require "rails_helper"
require "sidekiq/request_store_middleware"

RSpec.describe Sidekiq::RequestStoreMiddleware do
  let(:middleware) { described_class.new }
  let(:worker) { double("worker") } # rubocop:disable RSpec/VerifiedDoubles
  let(:job) { { "class" => "SomeWorker" } }
  let(:queue) { "default" }

  after { RequestStore.clear! }

  def run_job(&block)
    middleware.call(worker, job, queue, &block)
  end

  describe "#call" do
    it "yields to the job" do
      expect { |b| middleware.call(worker, job, queue, &b) }.to yield_control
    end

    it "starts the job with a fresh store, dropping anything a previous job left behind" do
      RequestStore.store[:subforem_id] = 123
      RequestStore.store["settings/community"] = { "community_name" => "Stale" }

      seen = nil
      run_job { seen = RequestStore.store.dup }

      expect(seen).to eq(Settings::Base::DEFAULT_SUBFOREM_FALLBACK_FLAG => true)
    end

    it "does not seed subforem request context, which scopes, feeds and URL helpers branch on" do
      seen = nil
      run_job { seen = RequestStore.store.slice(:subforem_id, :default_subforem_id, :root_subforem_id) }

      expect(seen).to be_empty
    end

    it "marks the store active only while the job runs" do
      active_during_job = nil
      run_job { active_during_job = RequestStore.active? }

      expect(active_during_job).to be(true)
      expect(RequestStore.active?).to be(false)
    end

    it "clears the store, including the settings flag, after the job" do
      run_job { RequestStore.store[:leaked] = true }

      expect(RequestStore.store).to eq({})
    end

    it "clears the store even when the job raises" do
      expect do
        run_job do
          RequestStore.store[:leaked] = true
          raise ArgumentError, "boom"
        end
      end.to raise_error(ArgumentError, "boom")

      expect(RequestStore.store).to eq({})
      expect(RequestStore.active?).to be(false)
    end
  end

  describe "settings freshness across jobs on the same thread" do
    it "lets a later job see a setting changed elsewhere after an earlier job read it" do
      Settings::Community.set_community_name("Old Name", subforem_id: nil)
      RequestStore.clear!

      first_read = nil
      run_job { first_read = Settings::Community.community_name }

      # Simulate a web process saving the setting: the row and Rails.cache change, but this thread's
      # RequestStore is not the one that process clears.
      Settings::Community.where(var: "community_name", subforem_id: nil).update_all(value: "New Name".to_yaml)
      Rails.cache.delete(Settings::Community.__send__(:cache_key))

      second_read = nil
      run_job { second_read = Settings::Community.community_name }

      expect(first_read).to eq("Old Name")
      expect(second_read).to eq("New Name")
    end
  end

  # Regressions for settings saved from the web admin (which lands on the default subforem's rows)
  # being invisible to Sidekiq jobs.
  describe "reading settings saved for the default subforem" do
    let!(:default_subforem) { create(:subforem) }

    before { create(:subforem) } # a second, non-default subforem

    it "applies spam trigger terms saved for the default subforem" do
      Settings::RateLimit.set_spam_trigger_terms(["buy followers"], subforem_id: default_subforem.id)
      RequestStore.clear!

      triggered = nil
      run_job { triggered = Settings::RateLimit.trigger_spam_for?(text: "Cheap BUY FOLLOWERS here") }

      expect(triggered).to be(true)
    end

    it "uses the default subforem's content spec for content without a subforem" do
      Settings::RateLimit.set_internal_content_description_spec("Global spec", subforem_id: nil)
      Settings::RateLimit.set_internal_content_description_spec("Default spec", subforem_id: default_subforem.id)
      RequestStore.clear!

      article = build(:article, subforem_id: nil)
      description = nil
      run_job do
        description = Ai::SpamEscalationCheck.new(text: "hi", content: article).__send__(:community_description)
      end

      expect(description).to eq("Default spec")
    end

    it "still reads the global value when the default subforem has no row of its own" do
      Settings::RateLimit.set_linked_domain_spam_score_threshold(1234, subforem_id: nil)
      RequestStore.clear!

      threshold = nil
      run_job { threshold = Settings::RateLimit.linked_domain_spam_score_threshold }

      expect(threshold).to eq(1234)
    end

    it "keeps the previous global-only behavior outside a job" do
      Settings::RateLimit.set_spam_trigger_terms(["buy followers"], subforem_id: default_subforem.id)
      RequestStore.clear!

      expect(Settings::RateLimit.trigger_spam_for?(text: "Cheap BUY FOLLOWERS here")).to be(false)
    end
  end
end
