require "rails_helper"

RSpec.describe MentorRelationship, type: :model do
  let(:mentor) { create(:user) }
  let(:mentee) { create(:user) }
  let(:relationship) { MentorRelationship.create(mentor_id: mentor.id, mentee_id: mentee.id) }

  it "is active" do
    expect(relationship.active).to eq(true)
  end

  it { is_expected.to belong_to(:mentor) }
  it { is_expected.to belong_to(:mentee) }

  it "is not the same user" do
    expect(MentorRelationship.create(mentor_id: mentor.id, mentee_id: mentor.id)).to be_invalid
  end

  it "cannot be a duplicate record" do
    relationship
    expect(MentorRelationship.create(mentor_id: mentor.id, mentee_id: mentee.id)).to be_invalid
  end
end
