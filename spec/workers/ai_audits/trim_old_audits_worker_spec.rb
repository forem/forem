require "rails_helper"

RSpec.describe AiAudits::TrimOldAuditsWorker do
  describe "#perform" do
    it "calls AiAudit.fast_trim_old_audits" do
      expect(AiAudit).to receive(:fast_trim_old_audits)

      described_class.new.perform
    end
  end
end
