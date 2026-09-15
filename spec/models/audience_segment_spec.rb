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

  describe "validations" do
    context "when segment is manual" do
      subject { build(:audience_segment, type_of: :manual) }

      it { is_expected.to validate_presence_of(:name) }
      it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
    end

    context "when segment is automatic" do
      subject { build(:audience_segment, type_of: :trusted, name: nil) }

      it { is_expected.to be_valid }
    end
  end

  describe "#display_name" do
    it "returns the name if present" do
      segment = build(:audience_segment, name: "Custom Beta Group")
      expect(segment.display_name).to eq("Custom Beta Group")
    end

    it "falls back to human readable description when name is blank" do
      segment = build(:audience_segment, type_of: :trusted, name: nil)
      expect(segment.display_name).to eq(described_class.human_readable_description_for(:trusted))
    end
  end

  describe "#user_count" do
    let(:segment) { create(:audience_segment) }
    let(:user) { create(:user) }

    it "returns the number of segmented users" do
      segment.segmented_users.create!(user: user)
      expect(segment.user_count).to eq(1)
    end
  end

  describe "destruction guards" do
    let!(:segment) { create(:audience_segment) }

    it "cannot be destroyed if associated with emails" do
      create(:email, status: "draft", audience_segment: segment)
      expect { segment.destroy }.not_to change(described_class, :count)
      expect(segment.errors[:base]).to include("Cannot delete record because dependent emails exist")
    end

    it "cannot be destroyed if associated with billboards" do
      create(:billboard, audience_segment: segment)
      expect { segment.destroy }.not_to change(described_class, :count)
      expect(segment.errors[:base]).to include("Cannot delete audience segment while in use by billboards.")
    end

    it "cannot destroy an automatic system segment" do
      system_segment = create(:audience_segment, type_of: :trusted, name: nil)
      expect { system_segment.destroy }.not_to change(described_class, :count)
      expect(system_segment.errors[:base]).to include("System audience segments cannot be destroyed.")
    end

    it "destroys clean manual segments successfully" do
      expect { segment.destroy }.to change(described_class, :count).by(-1)
    end
  end
end
