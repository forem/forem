require "rails_helper"

RSpec.describe AudienceSegmentRefreshAllWorker, type: :worker do
  let(:worker) { subject }
  let(:approved_and_published_ad) do
    create(:billboard, approved: true, published: true, audience_segment: create(:audience_segment))
  end

  before do
    create(:billboard, approved: false, published: true, audience_segment: create(:audience_segment))
    create(:billboard, approved: true, published: false, audience_segment: create(:audience_segment))
    create(:billboard, approved: false, published: false, audience_segment: create(:audience_segment))
    create(:billboard,
           approved: true,
           published: true,
           audience_segment: approved_and_published_ad.audience_segment)
  end

  include_examples "#enqueues_on_correct_queue", "low_priority"

  it "refreshes all active ads' segments", sidekiq: :inline do
    allow(AudienceSegment).to receive(:find).and_call_original
    segment = approved_and_published_ad.audience_segment
    worker.perform
    expect(AudienceSegment).to have_received(:find).with(segment.id).once
  end
end
