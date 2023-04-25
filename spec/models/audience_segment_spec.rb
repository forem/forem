require "rails_helper"

RSpec.describe AudienceSegment do
  subject(:audience_segment) { build(:audience_segment) }

  it { is_expected.to define_enum_for(:type_of) }
  it { is_expected.to be_valid }

  context "when persisting" do
    let(:active_users) { class_double(User) }

    before do
      audience_segment.save!
      allow(User).to receive(:recently_active).and_return(active_users)
      allow(active_users).to receive(:where).and_return([])
    end

    describe "refresh!" do
      it "does not refresh when manual" do
        expect(audience_segment).to be_manual
        audience_segment.refresh!
        expect(active_users).not_to have_received(:where)
      end

      it "queries User to refresh segments" do
        audience_segment.type_of = "no_posts_yet"
        audience_segment.refresh!
        expect(active_users).to have_received(:where).with(articles_count: 0)
      end
    end

    describe "save" do
      it "does not query when manual" do
        audience_segment.save!
        expect(active_users).not_to have_received(:where)
      end

      it "queries all Users (instead of active_users)" do
        audience_segment.type_of = "no_posts_yet"
        audience_segment.save!
        expect(active_users).to have_received(:where).with(articles_count: 0)
      end
    end
  end
end
