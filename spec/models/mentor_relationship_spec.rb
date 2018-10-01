require "rails_helper"

RSpec.describe MentorRelationship, type: :model do
  let(:mentor) { create(:user) }
  let(:mentee) { create(:user) }
  let(:relationship) { MentorRelationship.new(mentor: mentor, mentee_id: mentee) }

  describe "validations" do
    subject { MentorRelationship.new(mentor: mentor, mentee: mentee) }

    it { is_expected.to belong_to(:mentor) }
    it { is_expected.to belong_to(:mentee) }
    it { is_expected.to validate_uniqueness_of(:mentor_id).scoped_to(:mentee_id) }
  end

  it "is active" do
    expect(relationship.active).to eq(true)
  end

  it "is not the same user" do
    expect(MentorRelationship.new(mentor_id: mentor.id, mentee_id: mentor.id)).to be_invalid
  end
end
