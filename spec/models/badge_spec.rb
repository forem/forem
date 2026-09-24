require "rails_helper"

RSpec.describe Badge do
  let(:badge) { create(:badge) }
  let(:cache_bust) { instance_double(EdgeCache::Bust) }

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

      it "validates uniqueness of slug" do
        create(:badge, slug: "unique-slug")
        duplicate = build(:badge, slug: "unique-slug")
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:slug]).to include("has already been taken")
      end
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

  describe "#slug" do
    it "generates the correct slug for C when slug is blank" do
      badge = build(:badge, title: "C", slug: nil)
      badge.validate!

      expect(badge.slug).to eq("c")
    end

    it "generates the correct slug for C# when slug is blank" do
      badge = build(:badge, title: "C#", slug: nil)
      badge.validate!

      expect(badge.slug).to eq("c-23")
    end

    it "generates the correct slug for '16 Week Streak' when slug is blank" do
      badge = build(:badge, title: "16 Week Streak", slug: nil)
      badge.validate!

      expect(badge.slug).to eq("16-week-streak")
    end

    it "preserves an explicit slug on creation" do
      badge = build(:badge, title: "Community Favorite - 2 Gems", slug: "community-favorite-2")
      badge.validate!

      expect(badge.slug).to eq("community-favorite-2")
    end

    it "allows updating title without altering the existing slug" do
      badge = create(:badge, title: "Original Title", slug: "custom-slug")
      badge.update!(title: "Brand New Title")

      expect(badge.reload.title).to eq("Brand New Title")
      expect(badge.slug).to eq("custom-slug")
    end

    it "allows updating slug explicitly" do
      badge = create(:badge, title: "Original Title", slug: "original-slug")
      badge.update!(slug: "updated-slug")

      expect(badge.reload.slug).to eq("updated-slug")
    end

    it "regenerates slug from title when slug is cleared on update" do
      badge = create(:badge, title: "Original Title", slug: "original-slug")
      badge.update!(title: "Regenerated Title", slug: "")

      expect(badge.reload.slug).to eq("regenerated-title")
    end
  end
end
