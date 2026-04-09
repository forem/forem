require "rails_helper"

RSpec.describe Events::ManageBroadcastBillboardsWorker, type: :worker do
  describe "#perform" do
    let(:past_event) do
      create(:event, start_time: 2.hours.ago, end_time: 1.hour.ago, broadcast_config: "global_broadcast", published: true)
    end
    
    let(:active_event) do
      create(:event, start_time: 5.minutes.ago, end_time: 1.hour.from_now, broadcast_config: "tagged_broadcast", published: true)
    end

    let(:future_event) do
      create(:event, start_time: 1.hour.from_now, end_time: 2.hours.from_now, broadcast_config: "global_broadcast", published: true)
    end

    let(:no_broadcast_event) do
      create(:event, start_time: 5.minutes.ago, end_time: 1.hour.from_now, broadcast_config: "no_broadcast", published: true)
    end

    let!(:past_billboard) { create(:billboard, event: past_event, approved: true) }
    let!(:active_billboard) { create(:billboard, event: active_event, approved: false) }
    let!(:future_billboard) { create(:billboard, event: future_event, approved: false) }
    let!(:no_broadcast_billboard) { create(:billboard, event: no_broadcast_event, approved: true) } # should unapprove if somehow associated
    let!(:standard_billboard) { create(:billboard, event: nil, approved: true) }

    it "approves billboards for active broadcast events and unapproves for inactive ones" do
      described_class.new.perform

      expect(active_billboard.reload.approved).to eq(true)
      expect(past_billboard.reload.approved).to eq(false)
      expect(future_billboard.reload.approved).to eq(false)
      
      # Standard billboards remain untouched
      expect(standard_billboard.reload.approved).to eq(true)
    end

    it "purges edge caches when toggling statuses" do
      allow(EdgeCache::PurgeByKey).to receive(:call)

      described_class.new.perform

      expect(EdgeCache::PurgeByKey).to have_received(:call).with("main_app_home_page", fallback_paths: "/").at_least(:once)
      expect(EdgeCache::PurgeByKey).to have_received(:call).with(active_billboard.record_key).once
      expect(EdgeCache::PurgeByKey).to have_received(:call).with(past_billboard.record_key).once
      expect(EdgeCache::PurgeByKey).to have_received(:call).with(no_broadcast_billboard.record_key).once
    end

    context "when right at the border constraints" do
      let(:border_start_event) do
        create(:event, start_time: 14.minutes.from_now, end_time: 2.hours.from_now, broadcast_config: "global_broadcast", published: true)
      end

      let(:border_end_event) do
        create(:event, start_time: 2.hours.ago, end_time: 6.minutes.ago, broadcast_config: "global_broadcast", published: true)
      end

      let!(:border_start_bb) { create(:billboard, event: border_start_event, approved: false) }
      let!(:border_end_bb) { create(:billboard, event: border_end_event, approved: true) }

      it "approves exactly within 15 bounds, and disables exactly after 5 boundary limits" do
        described_class.new.perform
        expect(border_start_bb.reload.approved).to eq(true) # <= 15.minutes
        expect(border_end_bb.reload.approved).to eq(false) # <= -5.minutes (6.minutes.ago is completely expired)
      end
    end
  end
end
