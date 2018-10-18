require "rails_helper"

RSpec.describe MentorRelationship, type: :model do
  let(:mentor) { create(:user) }
  let(:mentee) { create(:user) }
  let(:relationship) { MentorRelationship.new(mentor_id: mentor.id, mentee_id: mentee.id) }

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

  it "makes the users follow one another" do
    relationship.save!
    expect(mentor.reload.following?(mentee)).to eq(true)
    expect(mentee.reload.following?(mentor)).to eq(true)
  end

  it "sends an email to both users" do
    relationship.save!
    expect(EmailMessage.all.size).to eq(2)
  end

  it "finds unmatched mentors" do
    expect(MentorRelationship.unmatched_mentors.size).to eq(0)
    new_mentor = create(:user, mentor_form_updated_at: Time.current, offering_mentorship: true)
    expect(MentorRelationship.unmatched_mentors.size).to eq(1)
    MentorRelationship.create(mentor_id: new_mentor.id, mentee_id: mentee.id)
    expect(MentorRelationship.unmatched_mentors.size).to eq(0)
  end

  it "finds unmatched mentees" do
    expect(MentorRelationship.unmatched_mentees.size).to eq(0)
    new_mentee = create(:user, mentee_form_updated_at: Time.current, seeking_mentorship: true)
    expect(MentorRelationship.unmatched_mentees.size).to eq(1)
    MentorRelationship.create(mentor_id: mentor.id, mentee_id: new_mentee.id)
    expect(MentorRelationship.unmatched_mentors.size).to eq(0)
  end
end
