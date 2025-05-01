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
