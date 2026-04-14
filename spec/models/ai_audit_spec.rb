require "rails_helper"

RSpec.describe AiAudit do
  describe ".fast_trim_old_audits" do
    let!(:old_audit) do
      create(:ai_audit,
        created_at: 35.days.ago,
        request_body: { "data" => "heavy_payload" },
        response_body: { "data" => "heavy_response" }
      )
    end

    let!(:recent_audit) do
      create(:ai_audit,
        created_at: 10.days.ago,
        request_body: { "data" => "recent_payload" },
        response_body: { "data" => "recent_response" }
      )
    end

    let!(:empty_old_audit) do
      create(:ai_audit,
        created_at: 35.days.ago,
        request_body: "{}",
        response_body: "{}"
      )
    end

    it "trims the request and response bodies of audits older than the threshold" do
      described_class.fast_trim_old_audits(30.days.ago)

      old_audit.reload
      expect(old_audit.request_body).to eq("{}")
      expect(old_audit.response_body).to eq("{}")
    end

    it "leaves recent audits completely untouched" do
      described_class.fast_trim_old_audits(30.days.ago)

      recent_audit.reload
      expect(recent_audit.request_body).to eq({ "data" => "recent_payload" })
      expect(recent_audit.response_body).to eq({ "data" => "recent_response" })
    end
  end
end
