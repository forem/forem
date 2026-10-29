require 'rails_helper'

RSpec.describe TagSubforemRelationship, type: :model do
  describe "associations" do
    it { should belong_to(:tag) }
    it { should belong_to(:subforem) }
  end

  describe "validations" do
    it { should validate_presence_of(:tag_id) }
    it { should validate_presence_of(:subforem_id) }
  end

  describe "database columns" do
    it { should have_db_column(:tag_id).of_type(:integer) }
    it { should have_db_column(:subforem_id).of_type(:integer) }
  end

  # validates :tag_id, presence: true, uniqueness: { scope: :subforem_id }
  # validates :subforem_id, presence: true, uniqueness: { scope: :tag_id }

  describe "supported tags cache purging" do
    before { allow(Tag).to receive(:purge_supported_tags) }

    it "purges the supported tags list on create" do
      create(:tag_subforem_relationship)
      expect(Tag).to have_received(:purge_supported_tags)
    end

    it "purges the supported tags list on update" do
      relationship = create(:tag_subforem_relationship)
      RSpec::Mocks.space.proxy_for(Tag).reset
      allow(Tag).to receive(:purge_supported_tags)

      relationship.update!(supported: false)
      expect(Tag).to have_received(:purge_supported_tags)
    end

    it "purges the supported tags list on destroy" do
      relationship = create(:tag_subforem_relationship)
      RSpec::Mocks.space.proxy_for(Tag).reset
      allow(Tag).to receive(:purge_supported_tags)

      relationship.destroy!
      expect(Tag).to have_received(:purge_supported_tags)
    end
  end

  describe "uniqueness validation" do
    let!(:tag_subforem_relationship) { create(:tag_subforem_relationship) }

    it "validates uniqueness of tag_id scoped to subforem_id" do
      duplicate_relationship = build(:tag_subforem_relationship, tag_id: tag_subforem_relationship.tag_id, subforem_id: tag_subforem_relationship.subforem_id)
      expect(duplicate_relationship).not_to be_valid
      expect(duplicate_relationship.errors[:tag_id]).to include("has already been taken")
    end

    it "validates uniqueness of subforem_id scoped to tag_id" do
      duplicate_relationship = build(:tag_subforem_relationship, tag_id: tag_subforem_relationship.tag_id, subforem_id: tag_subforem_relationship.subforem_id)
      expect(duplicate_relationship).not_to be_valid
      expect(duplicate_relationship.errors[:subforem_id]).to include("has already been taken")
    end
  end
end
