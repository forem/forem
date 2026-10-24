require "rails_helper"

RSpec.describe Billboards::TrackEmailClickWorker, type: :worker do
  let(:user) { create(:user) }
  let(:billboard) { create(:billboard, placement_area: "digest_first", published: true, approved: true) }

  describe "#perform" do
    it "creates a click BillboardEvent with user_agent and updates billboard counts", :aggregate_failures do
      create(:billboard_event, billboard: billboard, category: "impression", counts_for: 2, seconds_visible: 15)
      user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15"

      expect do
        described_class.new.perform(billboard.id, user.id, user_agent)
      end.to change(BillboardEvent, :count).by(1)

      event = BillboardEvent.last
      expect(event).to have_attributes(
        billboard_id: billboard.id,
        category: "click",
        user_id: user.id,
        context_type: "email",
        user_agent: user_agent,
      )

      billboard.reload
      expect(billboard.impressions_count).to eq(2)
      expect(billboard.clicks_count).to eq(1)
      expect(billboard.seconds_visible).to eq(15)
      expect(billboard.success_rate).to eq(0.5)
    end

    it "remains backwards-compatible when called without user_agent" do
      expect do
        described_class.new.perform(billboard.id, user.id)
      end.to change(BillboardEvent, :count).by(1)

      expect(BillboardEvent.last).to have_attributes(
        billboard_id: billboard.id,
        category: "click",
        user_id: user.id,
        context_type: "email",
        user_agent: nil,
      )
    end
  end
end
