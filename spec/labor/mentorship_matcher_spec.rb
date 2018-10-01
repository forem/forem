require "rails_helper"

RSpec.describe MentorshipMatcher do
  let(:user_one) { create(:user) }
  let(:user_two) { create(:user) }
  let(:user_three) { create(:user) }
  let(:user_four) { create(:user) }
  let(:user_five) { create(:user) }

  it "matches the correct pair of users" do
    mentor_ids = [user_one.id, user_two.id, user_three.id]
    mentee_ids = [user_three.id, user_four.id, user_five.id]
    described_class.match_mentees_and_mentors(mentee_ids, mentor_ids)
    expect(MentorRelationship.last.mentee_id).to eq(user_five.id)
  end
end
