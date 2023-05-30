require "rails_helper"

RSpec.describe SegmentedUsers::BulkDelete, type: :service do
  let(:audience_segment) { AudienceSegment.create!(type_of: "manual") }
  let(:users) { create_list(:user, 5) }

  it "removes only the passed users from the segment" do
    retained_users = create_list(:user, 3)

    audience_segment.users << users
    audience_segment.users << retained_users

    user_ids = users.map(&:id)
    result = described_class.call(audience_segment, user_ids: user_ids)
    expect(result.succeeded).to match_array(user_ids)
    expect(result.failed).to be_empty
    expect(audience_segment.users).to match_array(retained_users)
  end

  it "gracefully handles users that don't exist or aren't part of the segment" do
    user_in_segment = users.first
    audience_segment.users << user_in_segment

    user_not_in_segment = create(:user)
    user_ids = [user_in_segment.id, user_not_in_segment.id, "foo", 1_234_567_890]

    result = described_class.call(audience_segment, user_ids: user_ids)
    expect(result.succeeded).to contain_exactly(user_in_segment.id)
    expect(result.failed).to contain_exactly(user_not_in_segment.id, "foo", 1_234_567_890)
    expect(audience_segment.reload.users).to be_empty
  end
end
