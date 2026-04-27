require "rails_helper"

RSpec.describe CollectionIdAlias do
  describe "validations" do
    it { is_expected.to belong_to(:collection) }
    it { is_expected.to validate_presence_of(:legacy_collection_id) }

    it "validates uniqueness of legacy_collection_id" do
      user = create(:user)
      first_collection = create(:collection, user: user)
      second_collection = create(:collection, user: user)
      described_class.create!(legacy_collection_id: 123_456, collection: first_collection)

      duplicate_alias = described_class.new(legacy_collection_id: 123_456, collection: second_collection)
      expect(duplicate_alias).not_to be_valid
      expect(duplicate_alias.errors[:legacy_collection_id]).to include("has already been taken")
    end
  end
end
