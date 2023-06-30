require "rails_helper"

RSpec.describe SegmentedUsers::BulkUpsert, type: :service do
  let(:audience_segment) { AudienceSegment.create!(type_of: "manual") }
  let(:users) { create_list(:user, 5) }

  it "adds the users to the segment" do
    user_ids = users.map(&:id)
    result = described_class.call(audience_segment, user_ids: user_ids)
    expect(result.succeeded).to match_array(user_ids)
    expect(result.failed).to be_empty
    expect(audience_segment.users).to match_array(users)
  end

  it "retains any existing users in the segment" do
    existing_user = create(:user)
    audience_segment.users << [existing_user]

    user_ids = users.map(&:id)
    result = described_class.call(audience_segment, user_ids: user_ids)
    expect(result.succeeded).to match_array(user_ids)
    expect(result.failed).to be_empty
    expect(audience_segment.users).to contain_exactly(*users, existing_user)
  end

  it "only touches segmented users already in the list" do
    created_time = Time.current
    upsert_time = 3.days.from_now
    existing_users = create_list(:user, 3)
    existing_user_ids = existing_users.map(&:id)

    Timecop.freeze(created_time) do
      audience_segment.users << existing_users
    end

    Timecop.freeze(upsert_time) do
      user_ids = users.map(&:id) + existing_user_ids
      result = described_class.call(audience_segment, user_ids: user_ids)
      expect(result.succeeded).to match_array(user_ids)
      expect(result.failed).to be_empty

      existing_segmented_users = audience_segment.segmented_users.where(user_id: existing_user_ids)
      expect(existing_segmented_users.map(&:created_at)).to all(be_within(1.second).of(created_time))
      expect(existing_segmented_users.map(&:updated_at)).to all(be_within(1.second).of(upsert_time))
    end
  end

  it "only touches the segment if any users were successfully upserted" do
    user = create(:user)
    time = Time.current

    Timecop.freeze(time) do
      described_class.call(audience_segment, user_ids: [user.id])
      expect(audience_segment.updated_at).to be_within(1.second).of(time)

      Timecop.travel(1.day.from_now) do
        described_class.call(audience_segment, user_ids: [])
        expect(audience_segment.updated_at).to be_within(1.second).of(time)
      end

      Timecop.travel(2.days.from_now) do
        described_class.call(audience_segment, user_ids: [user.id])
        expect(audience_segment.updated_at).to be_within(1.second).of(Time.current)
      end
    end
  end

  it "gracefully handles users that don't exist" do
    real_user = create(:user)
    user_ids = [real_user.id, "foo", 1_234_567_890]
    result = described_class.call(audience_segment, user_ids: user_ids)

    expect(result.succeeded).to contain_exactly(real_user.id)
    expect(result.failed).to contain_exactly("foo", 1_234_567_890)
    expect(audience_segment.users).to contain_exactly(real_user)
  end

  it "returns immediately if the segment is not persisted" do
    audience_segment.destroy

    user_ids = users.map(&:id)
    result = described_class.call(audience_segment, user_ids: user_ids)
    expect(result).to be_nil
    expect(SegmentedUser.where(audience_segment_id: audience_segment.id)).to be_empty
  end
end
