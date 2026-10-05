require "rails_helper"
require "sidekiq/request_store_middleware"

RSpec.describe Sidekiq::RequestStoreMiddleware do
  let(:middleware) { described_class.new }
  let(:worker) { instance_double(Sidekiq::Job) }
  let(:job) { { "class" => "SomeWorker" } }
  let(:queue) { "default" }

  after { RequestStore.clear! }

  describe "#call" do
    it "yields to the job" do
      expect { |b| middleware.call(worker, job, queue, &b) }.to yield_control
    end

    it "starts the job with an empty store, dropping anything a previous job left behind" do
      RequestStore.store[:subforem_id] = 123
      RequestStore.store["settings/community"] = { "community_name" => "Stale" }

      seen = nil
      middleware.call(worker, job, queue) { seen = RequestStore.store.dup }

      expect(seen).to eq({})
    end

    it "marks the store active only while the job runs" do
      active_during_job = nil
      middleware.call(worker, job, queue) { active_during_job = RequestStore.active? }

      expect(active_during_job).to be(true)
      expect(RequestStore.active?).to be(false)
    end

    it "clears the store after the job" do
      middleware.call(worker, job, queue) { RequestStore.store[:leaked] = true }

      expect(RequestStore.store).to eq({})
    end

    it "clears the store even when the job raises" do
      expect do
        middleware.call(worker, job, queue) do
          RequestStore.store[:leaked] = true
          raise ArgumentError, "boom"
        end
      end.to raise_error(ArgumentError, "boom")

      expect(RequestStore.store).to eq({})
      expect(RequestStore.active?).to be(false)
    end

    it "lets a later job on the same thread see a setting changed elsewhere after an earlier job read it" do
      Settings::Community.set_community_name("Old Name", subforem_id: nil)
      RequestStore.clear!

      first_read = nil
      middleware.call(worker, job, queue) { first_read = Settings::Community.community_name }

      # Simulate a web dyno saving the setting: the row changes, but this thread's
      # RequestStore is not the one that process clears.
      Settings::Community.where(var: "community_name", subforem_id: nil)
        .update_all(value: "New Name".to_yaml)

      second_read = nil
      middleware.call(worker, job, queue) { second_read = Settings::Community.community_name }

      expect(first_read).to eq("Old Name")
      expect(second_read).to eq("New Name")
    end

    it "lets a job read settings saved for the default subforem" do
      default_subforem = create(:subforem)
      create(:subforem)
      Settings::RateLimit.set_internal_content_description_spec("Global spec", subforem_id: nil)
      Settings::RateLimit.set_internal_content_description_spec("DEV spec", subforem_id: default_subforem.id)
      RequestStore.clear!

      spec = nil
      middleware.call(worker, job, queue) { spec = Settings::RateLimit.internal_content_description_spec }

      expect(spec).to eq("DEV spec")
    end
  end
end
