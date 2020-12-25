require "rails_helper"

RSpec.describe Badge, type: :model do
  let(:badge) { create(:badge) }

  describe "validations" do
    describe "builtin validations" do
      subject { badge }

      it { is_expected.to have_many(:badge_achievements).dependent(:restrict_with_error) }
      it { is_expected.to have_many(:tags).dependent(:restrict_with_error) }
      it { is_expected.to have_many(:users).through(:badge_achievements) }

      it { is_expected.to validate_presence_of(:badge_image) }
      it { is_expected.to validate_presence_of(:description) }
      it { is_expected.to validate_presence_of(:title) }
      it { is_expected.to validate_uniqueness_of(:title) }
    end
  end

  describe "class methods" do
    describe ".id_for_slug" do
      it "returns the id of an existing slug" do
        expect(described_class.id_for_slug(badge.slug)).to eq badge.id
      end

      it "returns nil for non-existing slugs" do
        expect(described_class.id_for_slug("ohnoes")).to be_nil
      end
    end
  end

  context "when callbacks are triggered after save" do
    let!(:badge) { create(:badge) }

    describe "cache busting" do
      before do
        allow(CacheBuster).to receive(:bust)
      end

      it "calls the cache buster with the path" do
        badge.save

        expect(CacheBuster).to have_received(:bust).with(badge.path)
      end

      it "calls the cache buster with the internal path" do
        badge.save

        expect(CacheBuster).to have_received(:bust).with("#{badge.path}?i=i")
      end
    end
  end

  describe "#path" do
    it "returns the path of the badge" do
      expect(badge.path).to eq("/badge/#{badge.slug}")
    end
  end

  describe "#slug" do
    it "generates the correct slug for C" do
      badge = build(:badge, title: "C")
      badge.validate!

      expect(badge.slug).to eq("c")
    end

    it "generates the correct slug for C#" do
      badge = build(:badge, title: "C#")
      badge.validate!

      expect(badge.slug).to eq("c-23")
    end

    it "generates the correct slug for '16 Week Streak'" do
      badge = build(:badge, title: "16 Week Streak")
      badge.validate!

      expect(badge.slug).to eq("16-week-streak")
    end
  end
end
