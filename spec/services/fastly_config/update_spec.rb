require "rails_helper"

RSpec.describe FastlyConfig::Update, type: :service do
  let(:fastly) { instance_double(Fastly) }
  let(:fastly_service) { instance_double(Fastly::Service) }
  let(:fastly_version) { instance_double(Fastly::Version) }
  let(:fastly_snippet) { instance_double(Fastly::Snippet) }
  let(:fastly_updater) { described_class.new }

  # Fastly isn't setup for test or development environments so we have to stub
  # quite a bit here to simulate Fastly working ¯\_(ツ)_/¯
  before do
    allow(Fastly).to receive(:new).and_return(fastly)
    allow(fastly).to receive(:get_service).and_return(fastly_service)
    allow(described_class).to receive(:new).and_return(fastly_updater)
    allow(fastly_updater).to receive(:get_active_version).and_return(fastly_version)
    allow(fastly_updater).to receive(:fastly).and_return(fastly)
    allow(fastly_updater).to receive(:service).and_return(fastly_service)
    allow(fastly_version).to receive(:number).and_return(1)
    allow(fastly).to receive(:get_snippet).and_return(fastly_snippet)
    allow(fastly_version).to receive(:clone).and_return(fastly_version)
    allow(fastly_version).to receive(:number).and_return(99)
    allow(fastly_version).to receive(:activate!).and_return(true)
  end

  describe "::run" do
    it "raises an error for incorrectly formatted configs" do
      expect { fastly_updater.run(configs: "Not an Array") }.to raise_error(FastlyConfig::Errors::InvalidConfigsFormat)
    end

    it "raises an error for invalid configs" do
      expect { fastly_updater.run(configs: ["Invalid config"]) }.to raise_error(FastlyConfig::Errors::InvalidConfig)
    end

    it "doesn't update if the params haven't changed" do
      stub_const("#{described_class}::FASTLY_CONFIGS", ["Snippets"])
      snippet_handler = instance_double FastlyConfig::Snippets
      allow(FastlyConfig::Snippets).to receive(:new).and_return(snippet_handler)
      allow(snippet_handler).to receive(:update_needed?).and_return(false)
      described_class.call
      expect(fastly_version).not_to have_received(:clone)
    end

    it "updates Fastly if new updates are found" do
      stub_const("#{described_class}::FASTLY_CONFIGS", ["Snippets"])
      snippet_handler = instance_double FastlyConfig::Snippets
      allow(FastlyConfig::Snippets).to receive(:new).and_return(snippet_handler)
      allow(snippet_handler).to receive(:update_needed?).and_return(true)
      allow(snippet_handler).to receive(:update).and_return(true)
      described_class.call
      expect(fastly_version).to have_received(:activate!)
    end

    it "logs success messages" do
      allow(Rails.logger).to receive(:info)
      allow(ForemStatsClient).to receive(:increment)

      stub_const("#{described_class}::FASTLY_CONFIGS", ["Snippets"])
      snippet_handler = instance_double FastlyConfig::Snippets
      allow(FastlyConfig::Snippets).to receive(:new).and_return(snippet_handler)
      allow(snippet_handler).to receive(:update_needed?).and_return(true)
      allow(snippet_handler).to receive(:update).and_return(true)

      described_class.call
      expect(Rails.logger).to have_received(:info)

      tags = hash_including(tags: array_including("new_version:#{fastly_version.number}", "configs_updated:Snippets"))

      expect(ForemStatsClient).to have_received(:increment).with("fastly.update", tags)
    end
  end
end
