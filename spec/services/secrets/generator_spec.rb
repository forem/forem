require "rails_helper"

RSpec.describe Secrets::Generator, type: :service do
  describe ".sortable" do
    it "generates unique identifiers" do
      expect(described_class.sortable).not_to eq(described_class.sortable)
    end

    it "generates sortable identifiers" do
      now_id = described_class.sortable
      a_month_from_now_id = described_class.sortable(1.month.from_now)
      a_month_ago_id = described_class.sortable(1.month.ago)

      expected_ids = [a_month_ago_id, now_id, a_month_from_now_id]
      expect([now_id, a_month_from_now_id, a_month_ago_id].sort).to eq(expected_ids)
    end
  end
end
