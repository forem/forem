require "rails_helper"

RSpec.describe FastlyConfig::CustomDomainDictionary, type: :service do
  let(:service_id) { "svc-test-123" }
  let(:dict_id) { "dict-test-456" }
  let!(:active_org) { create(:organization, slug: "mlh", custom_domain: "blog.mlh.com") }
  let!(:disabled_org) { create(:organization, slug: "disabledorg", custom_domain: "blog.disabled.org") }

  def stub_http_response(code:, body:)
    instance_double(
      HTTParty::Response,
      code: code,
      success?: code.between?(200, 299),
      body: body.to_json,
      parsed_response: body,
    )
  end

  before do
    MemoryFirstCache.delete("fastly_dictionary_id:#{service_id}:custom_domain_orgs")
    allow(Settings::General).to receive(:app_domain).and_return("forem.com")
    allow(ApplicationConfig).to receive(:[]).and_call_original
    allow(ApplicationConfig).to receive(:[]).with("FASTLY_API_KEY").and_return("fastly-secret-key")
    allow(ApplicationConfig).to receive(:[]).with("FASTLY_SERVICE_ID").and_return(service_id)
    FeatureFlag.enable(:org_custom_domain, FeatureFlag::Actor.new(active_org))
    FeatureFlag.disable(:org_custom_domain, FeatureFlag::Actor.new(disabled_org))
  end

  describe ".desired_items" do
    it "includes app_domain and bidirectional mappings only for enabled custom-domain organizations" do
      expect(described_class.desired_items).to eq(
        "app_domain" => "forem.com",
        "slug:mlh" => "blog.mlh.com",
        "domain:blog.mlh.com" => "mlh",
      )
    end
  end

  describe ".sync_all!" do
    it "reconciles stale and missing items via batch PATCH" do
      allow(described_class).to receive(:get)
        .with("/service/#{service_id}/version/active", anything)
        .and_return(stub_http_response(code: 200, body: { "number" => 7 }))
      allow(described_class).to receive(:get)
        .with("/service/#{service_id}/version/7/dictionary/custom_domain_orgs", anything)
        .and_return(stub_http_response(code: 200, body: { "id" => dict_id }))
      allow(described_class).to receive(:get)
        .with("/service/#{service_id}/dictionary/#{dict_id}/items", anything)
        .and_return(
          stub_http_response(
            code: 200,
            body: [
              { "item_key" => "app_domain", "item_value" => "forem.com" },
              { "item_key" => "slug:stale", "item_value" => "old.example.com" },
            ],
          ),
        )
      allow(described_class).to receive(:patch)
        .and_return(stub_http_response(code: 200, body: { "status" => "ok" }))

      expect(described_class.sync_all!).to be true

      expect(described_class).to have_received(:patch).with(
        "/service/#{service_id}/dictionary/#{dict_id}/items",
        hash_including(
          body: satisfy do |json_body|
            ops = JSON.parse(json_body).fetch("items")
            ops.include?({ "op" => "delete", "item_key" => "slug:stale" }) &&
              ops.include?({ "op" => "upsert", "item_key" => "slug:mlh", "item_value" => "blog.mlh.com" }) &&
              ops.include?({ "op" => "upsert", "item_key" => "domain:blog.mlh.com", "item_value" => "mlh" }) &&
              ops.none? { |op| op["item_key"] == "app_domain" }
          end,
        ),
      )
    end
  end

  describe ".sync_organization!" do
    before do
      allow(described_class).to receive(:get)
        .with("/service/#{service_id}/version/active", anything)
        .and_return(stub_http_response(code: 200, body: { "number" => 7 }))
      allow(described_class).to receive(:get)
        .with("/service/#{service_id}/version/7/dictionary/custom_domain_orgs", anything)
        .and_return(stub_http_response(code: 200, body: { "id" => dict_id }))
      allow(described_class).to receive_messages(
        patch: stub_http_response(code: 200, body: { "status" => "ok" }),
        delete: stub_http_response(code: 404, body: { "msg" => "Record not found" }),
      )
    end

    it "upserts current mappings and deletes previous slug and domain keys when updated" do
      expect(
        described_class.sync_organization!(
          active_org.id,
          previous_slug: "oldmlh",
          previous_custom_domain: "old.mlh.com",
        ),
      ).to be true

      expect(described_class).to have_received(:delete).with(
        "/service/#{service_id}/dictionary/#{dict_id}/item/slug%3Aoldmlh",
        anything,
      )
      expect(described_class).to have_received(:delete).with(
        "/service/#{service_id}/dictionary/#{dict_id}/item/domain%3Aold.mlh.com",
        anything,
      )
      expect(described_class).to have_received(:patch).with(
        "/service/#{service_id}/dictionary/#{dict_id}/items",
        hash_including(
          body: satisfy do |json_body|
            ops = JSON.parse(json_body).fetch("items")
            ops.include?({ "op" => "upsert", "item_key" => "slug:mlh", "item_value" => "blog.mlh.com" }) &&
              ops.include?({ "op" => "upsert", "item_key" => "domain:blog.mlh.com", "item_value" => "mlh" })
          end,
        ),
      )
    end

    it "deletes slug and domain keys when the feature flag is disabled" do
      expect(described_class.sync_organization!(disabled_org.id)).to be true

      expect(described_class).to have_received(:delete).with(
        "/service/#{service_id}/dictionary/#{dict_id}/item/slug%3Adisabledorg",
        anything,
      )
      expect(described_class).to have_received(:delete).with(
        "/service/#{service_id}/dictionary/#{dict_id}/item/domain%3Ablog.disabled.org",
        anything,
      )
    end
  end
end
