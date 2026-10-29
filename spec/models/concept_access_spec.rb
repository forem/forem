require "rails_helper"

RSpec.describe ConceptAccess, type: :model do
  describe "validations" do
    it "is valid with user and concept" do
      access = build(:concept_access)
      expect(access).to be_valid
    end

    it "requires user_id and concept_id" do
      expect(build(:concept_access, user: nil)).not_to be_valid
      expect(build(:concept_access, concept: nil)).not_to be_valid
    end

    it "enforces uniqueness of user_id scoped to concept_id" do
      access = create(:concept_access)
      duplicate = build(:concept_access, user: access.user, concept: access.concept)
      expect(duplicate).not_to be_valid
    end
  end
end
