require "rails_helper"

RSpec.describe FastlyVCL::SafeParams, type: :service do
  let(:fastly) { instance_double(Fastly) }
  let(:fastly_service) { instance_double(Fastly::Service) }
  let(:fastly_version) { instance_double(Fastly::Version) }
  let(:fastly_snippet) { instance_double(Fastly::Snippet) }
  let(:file_params) { YAML.load_file("config/fastly/safe_params.yml") }
  let(:snippet_content) do
    "#{described_class::VCL_DELIMITER_START}#{file_params.join('|')}#{described_class::VCL_DELIMITER_END}"
  end

  # Fastly isn't setup for test or development environments so we have to stub
  # quite a bit here to simulate Fastly working ¯\_(ツ)_/¯
  before do
    allow(Fastly).to receive(:new).and_return(fastly)
    allow(fastly).to receive(:get_service).and_return(fastly_service)
    allow(fastly_service).to receive(:version).and_return(fastly_version)
    allow(fastly_version).to receive(:number).and_return(1)
    allow(fastly).to receive(:get_snippet).and_return(fastly_snippet)
    allow(fastly_snippet).to receive(:content).and_return(snippet_content)
    allow(fastly_version).to receive(:clone).and_return(fastly_version)
    allow(fastly_version).to receive(:number).and_return(99)
    allow(described_class).to receive(:build_content).and_return(snippet_content)
    allow(fastly_snippet).to receive(:content).and_return(fastly_snippet)
    allow(described_class).to receive(:params_to_array).and_return(file_params)
    allow(fastly_snippet).to receive(:content=).and_return(snippet_content)
    allow(fastly_snippet).to receive(:save!).and_return(true)
    allow(fastly_version).to receive(:activate!).and_return(true)
  end

  describe "::update" do
    it "doesn't update if the params haven't changed" do
      described_class.update
      expect(fastly_version).not_to have_received(:clone)
    end

    it "updates Fastly if new params are added" do
      new_params = file_params + ["new_param"]
      stub_const("#{described_class}::FILE_PARAMS", new_params)
      described_class.update
      expect(fastly_version).to have_received(:activate!)
    end

    it "updates Fastly if params are removed" do
      new_params = file_params - [file_params.last]
      stub_const("#{described_class}::FILE_PARAMS", new_params)
      described_class.update
      expect(fastly_version).to have_received(:activate!)
    end

    it "overwrites updates made directly in Fastly" do
      new_fastly_params = file_params + ["new_fastly_param"]
      allow(described_class).to receive(:params_to_array).and_return(new_fastly_params)
      described_class.update
      expect(fastly_version).to have_received(:activate!)
    end

    it "logs success messages" do
      allow(Rails.logger).to receive(:info)
      allow(DatadogStatsClient).to receive(:increment)

      old_param = file_params.last
      new_params = file_params + ["new_param"] - [old_param]
      stub_const("#{described_class}::FILE_PARAMS", new_params)
      described_class.update

      expect(Rails.logger).to have_received(:info)

      tags = hash_including(tags: array_including("added_params:new_param", "removed_params:#{old_param}", "new_version:#{fastly_version.number}"))

      expect(DatadogStatsClient).to have_received(:increment).with("fastly.safelist", tags)
    end
  end
end
