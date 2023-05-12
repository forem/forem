require "rails_helper"

RSpec.describe BulkSegmentedUsers, type: :service do
  describe ".upsert" do
    context "when segment is a manual audience segment" do
      let(:audience_segment) { AudienceSegment.create!(type_of: "manual") }
      let(:users) { create_list(:user, 5) }

      it "adds the users to the segment" do
        user_ids = users.map(&:id)
        result = described_class.upsert(audience_segment, user_ids: user_ids)
        expect(result[:succeeded]).to match_array(user_ids)
        expect(result[:failed]).to be_empty
        expect(audience_segment.users).to match_array(users)
      end

      it "retains any existing users in the segment" do
        existing_user = create(:user)
        audience_segment.users << [existing_user]

        user_ids = users.map(&:id)
        result = described_class.upsert(audience_segment, user_ids: user_ids)
        expect(result[:succeeded]).to match_array(user_ids)
        expect(result[:failed]).to be_empty
        expect(audience_segment.users).to contain_exactly(*users, existing_user)
      end

      it "only touches updated_at timestamp of existing segmented users in the list" do
        created_time = Time.current
        upsert_time = 3.days.from_now
        existing_users = create_list(:user, 3)
        existing_user_ids = existing_users.map(&:id)

        Timecop.freeze(created_time) do
          audience_segment.users << existing_users
        end

        Timecop.freeze(upsert_time) do
          user_ids = users.map(&:id) + existing_user_ids
          result = described_class.upsert(audience_segment, user_ids: user_ids)
          expect(result[:succeeded]).to match_array(user_ids)
          expect(result[:failed]).to be_empty

          existing_segmented_users = audience_segment.segmented_users.where(user_id: existing_user_ids)
          expect(existing_segmented_users.map(&:created_at)).to all(eq(created_time))
          expect(existing_segmented_users.map(&:updated_at)).to all(eq(upsert_time))
        end
      end

      it "gracefully handles users that don't exist" do
        real_user = create(:user)
        user_ids = [real_user.id, "foo", 1_234_567_890]
        result = described_class.upsert(audience_segment, user_ids: user_ids)

        expect(result[:succeeded]).to contain_exactly(real_user.id)
        expect(result[:failed]).to contain_exactly("foo", 1_234_567_890)
        expect(audience_segment.users).to contain_exactly(real_user)
      end
    end

    context "when segment is not a manual audience segment" do
      let(:audience_segment) { AudienceSegment.create!(type_of: "trusted") }
      let(:users) { create_list(:user, 5) }

      it "does not add the users to the segment" do
        allow(User).to receive(:with_role).and_return([])

        user_ids = users.map(&:id)
        result = described_class.upsert(audience_segment, user_ids: user_ids)
        expect(result).to be_nil
        expect(audience_segment.users).to be_empty
      end
    end
  end

  describe ".delete" do
    context "when segment is a manual audience segment" do
      let(:audience_segment) { AudienceSegment.create!(type_of: "manual") }
      let(:users) { create_list(:user, 5) }

      it "removes only the passed users from the segment" do
        retained_users = create_list(:user, 3)

        audience_segment.users << users
        audience_segment.users << retained_users

        user_ids = users.map(&:id)
        result = described_class.delete(audience_segment, user_ids: user_ids)
        expect(result[:succeeded]).to match_array(user_ids)
        expect(result[:failed]).to be_empty
        expect(audience_segment.users).to match_array(retained_users)
      end

      it "gracefully handles users that don't exist or aren't part of the segment" do
        user_in_segment = users.first
        audience_segment.users << user_in_segment

        user_not_in_segment = create(:user)
        user_ids = [user_in_segment.id, user_not_in_segment.id, "foo", 1_234_567_890]

        result = described_class.delete(audience_segment, user_ids: user_ids)
        expect(result[:succeeded]).to contain_exactly(user_in_segment.id)
        expect(result[:failed]).to contain_exactly(user_not_in_segment.id, "foo", 1_234_567_890)
        expect(audience_segment.reload.users).to be_empty
      end
    end

    context "when segment is not a manual audience segment" do
      let(:audience_segment) { AudienceSegment.create!(type_of: "trusted") }
      let(:users) { create_list(:user, 5) }

      it "does not remove any users from the segment" do
        allow(User).to receive(:with_role).and_return(users)

        user_ids = users.map(&:id)
        result = described_class.delete(audience_segment, user_ids: user_ids)
        expect(result).to be_nil
        expect(audience_segment.users).to match_array(users)
      end
    end
  end
end
