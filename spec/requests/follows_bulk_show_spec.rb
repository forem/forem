require "rails_helper"

RSpec.describe "Follows #bulk_show", type: :request do
  let(:current_user) { create(:user) }
  let(:user) { create(:user) }
  let(:user_two) { create(:user) }

  before { sign_in current_user }

  it "returns false when not following" do
    current_user.follow(user)
    get "/follows/bulk_show", params: { ids: [user.id, user_two.id, current_user.id] }

    expect(response.parsed_body[current_user.id.to_s]).to eq("self")
    expect(response.parsed_body[user.id.to_s]).to eq("true")
    expect(response.parsed_body[user_two.id.to_s]).to eq("false")
  end
end
