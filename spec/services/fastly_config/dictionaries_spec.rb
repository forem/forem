require "rails_helper"

RSpec.describe FastlyConfig::Dictionaries, type: :service do
  let(:fastly) { instance_double(Fastly) }
  let(:active_version) { instance_double(Fastly::Version, number: 1) }
  let(:new_version) { instance_double(Fastly::Version, number: 2) }
  let(:fastly_dictionary) { instance_double(Fastly::Dictionary, name: "custom_domain_orgs") }

  before do
    allow(ApplicationConfig).to receive(:[]).and_call_original
    allow(ApplicationConfig).to receive(:[]).with("FASTLY_SERVICE_ID").and_return("svc-123")
  end

  it "reports update_needed? as true when custom_domain_orgs is missing on the active version" do
    allow(fastly).to receive(:get_dictionary)
      .with("svc-123", 1, "custom_domain_orgs")
      .and_raise(Fastly::Error.new('{"msg":"Record not found"}'))

    config = described_class.new(fastly, active_version)
    expect(config.update_needed?).to be true
  end

  it "reports update_needed? as false when custom_domain_orgs already exists on the active version" do
    allow(fastly).to receive(:get_dictionary)
      .with("svc-123", 1, "custom_domain_orgs")
      .and_return(fastly_dictionary)

    config = described_class.new(fastly, active_version)
    expect(config.update_needed?).to be false
  end

  it "creates the dictionary on the cloned version and increments stats" do
    allow(ForemStatsClient).to receive(:increment)
    allow(fastly).to receive(:get_dictionary)
      .with("svc-123", 1, "custom_domain_orgs")
      .and_raise(Fastly::Error.new('{"msg":"Record not found"}'))
    allow(fastly).to receive(:get_dictionary)
      .with("svc-123", 2, "custom_domain_orgs")
      .and_raise(Fastly::Error.new('{"msg":"Record not found"}'))
    allow(fastly).to receive(:create).with(
      Fastly::Dictionary,
      {
        name: "custom_domain_orgs",
        service_id: "svc-123",
        version: 2
      },
    ).and_return(fastly_dictionary)

    config = described_class.new(fastly, active_version)
    config.update(new_version)

    expect(fastly).to have_received(:create).with(
      Fastly::Dictionary,
      {
        name: "custom_domain_orgs",
        service_id: "svc-123",
        version: 2
      },
    )
    expect(ForemStatsClient).to have_received(:increment).with(
      "fastly.dictionaries",
      hash_including(
        tags: array_including(
          "dictionary_update_type:create",
          "dictionary_name:custom_domain_orgs",
          "new_version:2",
        ),
      ),
    )
  end
end
