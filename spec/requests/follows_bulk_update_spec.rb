require "rails_helper"

RSpec.describe "Following/Unfollowing", type: :request do
  let(:user) { create(:user) }
  let(:user_2) { create(:user) }
  let(:tags) { create_list(:tag, 2) }
  let(:follow_1) { create(:follow, follower: user, followable: tags[0]) }
  let(:follow_2) { create(:follow, follower: user, followable: tags[1]) }

  before do
    sign_in user
  end

  describe "PATCH bulk_update" do
    let(:params) { [{ id: follow_1.id, explicit_points: 3.0 }, { id: follow_2.id, explicit_points: 10.0 }] }

    it "bulk updates follow explicit_points" do
      patch "/follows/bulk_update", params: { follows: params }
      expect(Follow.find(follow_1.id).explicit_points).to eq(3.0)
      expect(Follow.find(follow_1.id).points).to eq(3.0)
      expect(Follow.find(follow_2.id).explicit_points).to eq(10.0)
      expect(Follow.find(follow_2.id).points).to eq(10.0)
    end

    it "does not update if follow does not belong to user" do
      user_2.follow(tags[0])
      expect do
        patch "/follows/bulk_update", params: { follows: [{ id: Follow.last.id, explicit_points: 3.0 }] }
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end
end
