require "rails_helper"

RSpec.describe Collection do
  let(:user) { create(:user) }
  let(:collection) { create(:collection, :with_articles, user: user) }

  describe "validations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:organization).optional }
    it { is_expected.to have_many(:articles).dependent(:nullify) }

    it { is_expected.to validate_presence_of(:slug) }

    describe "slug uniqueness" do
      context "for personal collections (no organization)" do
        it "enforces uniqueness within user_id" do
          create(:collection, user: user, slug: "test-slug", organization: nil)
          duplicate = build(:collection, user: user, slug: "test-slug", organization: nil)
          expect(duplicate).not_to be_valid
          expect(duplicate.errors[:slug]).to be_present
        end

        it "allows same slug for different users" do
          other_user = create(:user)
          create(:collection, user: user, slug: "test-slug", organization: nil)
          other_collection = build(:collection, user: other_user, slug: "test-slug", organization: nil)
          expect(other_collection).to be_valid
        end
      end

      context "for organization collections" do
        let(:organization) { create(:organization) }

        it "enforces uniqueness within organization_id (not user_id)" do
          create(:collection, user: user, slug: "test-slug", organization: organization)
          # Even with a different user, same slug + organization should fail
          other_user = create(:user)
          duplicate = build(:collection, user: other_user, slug: "test-slug", organization: organization)
          expect(duplicate).not_to be_valid
          expect(duplicate.errors[:slug]).to include("has already been taken for this organization")
        end

        it "allows same slug for different organizations" do
          other_organization = create(:organization)
          create(:collection, user: user, slug: "test-slug", organization: organization)
          other_collection = build(:collection, user: user, slug: "test-slug", organization: other_organization)
          expect(other_collection).to be_valid
        end
      end
    end
  end

  describe ".find_series" do
    let!(:other_user) { create(:user) }
    let!(:series) { collection }

    it "returns an existing series" do
      expect do
        expect(described_class.find_series(series.slug, series.user)).to eq(series)
      end.not_to change(described_class, :count)
    end

    it "creates a new series for a user if an existing one is not found" do
      slug = Faker::Books::CultureSeries.book
      expect { described_class.find_series(slug, other_user) }.to change(described_class, :count).by(1)
    end

    it "creates a new series with an existing slug for a new user" do
      expect { described_class.find_series(series.slug, other_user) }.to change(described_class, :count).by(1)
    end

    context "with organization" do
      let(:organization) { create(:organization) }

      it "creates a new series for an organization" do
        slug = Faker::Books::CultureSeries.book
        expect do
          collection = described_class.find_series(slug, user, organization: organization)
          expect(collection.organization).to eq(organization)
        end.to change(described_class, :count).by(1)
      end

      it "returns an existing series for an organization regardless of user_id" do
        # Create a collection with one user
        original_user = create(:user)
        org_collection = create(:collection, user: original_user, organization: organization, slug: "test-series")
        
        # Try to find it with a different user - should return the existing collection
        different_user = create(:user)
        expect do
          found_collection = described_class.find_series("test-series", different_user, organization: organization)
          expect(found_collection).to eq(org_collection)
          expect(found_collection.user_id).to eq(original_user.id) # Should still be the original user
        end.not_to change(described_class, :count)
      end

      it "returns an existing series for an organization when called by the same user" do
        org_collection = create(:collection, user: user, organization: organization, slug: "test-series")
        expect do
          expect(described_class.find_series("test-series", user, organization: organization)).to eq(org_collection)
        end.not_to change(described_class, :count)
      end

      it "allows same slug for different organizations" do
        org1 = create(:organization)
        org2 = create(:organization)
        slug = "shared-slug"

        collection1 = described_class.find_series(slug, user, organization: org1)
        collection2 = described_class.find_series(slug, user, organization: org2)

        expect(collection1).not_to eq(collection2)
        expect(collection1.slug).to eq(collection2.slug)
        expect(collection1.organization).to eq(org1)
        expect(collection2.organization).to eq(org2)
      end
    end
  end

  describe "path" do
    it "returns the correct path" do
      expect(collection.path).to eq("/#{collection.user.username}/series/#{collection.id}")
    end
  end

  context "when callbacks are triggered after touch" do
    it "touches all articles in the collection" do
      before_times = collection.articles.order(updated_at: :desc).pluck(:updated_at).map(&:to_i)

      Timecop.freeze(1.month.from_now) do
        collection.touch
      end

      after_times = collection.reload.articles.order(updated_at: :desc).pluck(:updated_at).map(&:to_i)

      all_before = after_times.each_with_index.map { |v, i| v > before_times[i] }
      expect(all_before.all?).to be(true)
    end
  end
end
