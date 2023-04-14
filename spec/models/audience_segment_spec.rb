require "rails_helper"

RSpec.describe AudienceSegment do
  subject(:audience_segment) { build(:audience_segment) }

  it { is_expected.to define_enum_for(:type_of) }
  it { is_expected.to be_valid }

  context "when refreshing" do
    before do
      audience_segment.save!
      allow(User).to receive(:where).and_return([])
    end

    it "does not refresh when manual" do
      expect(audience_segment).to be_manual
      audience_segment.refresh!
      expect(User).not_to have_received(:where)
    end

    it "queries User to refresh segments" do
      audience_segment.type_of = "no_posts_yet"
      audience_segment.refresh!
      expect(User).to have_received(:where).with(articles_count: 0)
    end
  end
end
