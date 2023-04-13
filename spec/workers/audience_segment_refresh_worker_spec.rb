require "rails_helper"

RSpec.describe AudienceSegmentRefreshWorker, type: :worker do
  let(:worker) { subject }
  let(:fake_segment) { instance_double AudienceSegment, refresh!: :refreshed }
  let(:segment_finder) { class_double AudienceSegment }

  before do
    allow(segment_finder).to receive(:find_each).and_yield(fake_segment)
    allow(AudienceSegment).to receive(:where).and_return(segment_finder)
  end

  include_examples "#enqueues_on_correct_queue", "low_priority"

  it "refreshes a segment by id" do
    worker.perform(123)
    expect(AudienceSegment).to have_received(:where).with(id: [123])
    expect(fake_segment).to have_received(:refresh!)
  end

  it "refreshes segments via ids" do
    worker.perform(123, 345)
    expect(AudienceSegment).to have_received(:where).with(id: [123, 345])
    expect(fake_segment).to have_received(:refresh!)
  end

  context "when no ids are supplied" do
    let(:approved_and_published_ad) do
      create(:display_ad,
             approved: true,
             published: true,
             audience_segment: create(:audience_segment))
    end

    before do
      create(:display_ad,
             approved: false,
             published: true,
             audience_segment: create(:audience_segment))
      create(:display_ad,
             approved: true,
             published: false,
             audience_segment: create(:audience_segment))
      create(:display_ad,
             approved: false,
             published: false,
             audience_segment: create(:audience_segment))

      create(:display_ad,
             approved: true,
             published: true,
             audience_segment: approved_and_published_ad.audience_segment)
    end

    it "refreshes all active ads' segments" do
      worker.perform
      expect(AudienceSegment).to have_received(:where)
        .with(id: [approved_and_published_ad.audience_segment_id])
      expect(fake_segment).to have_received(:refresh!)
    end
  end
end
