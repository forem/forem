require "rails_helper"

RSpec.describe "Follows #bulk_show" do
  let(:current_user)      { create(:user) }
  let(:followed_user)     { create(:user) }
  let(:not_followed_user) { create(:user) }
  let(:follow_back_user)  { create(:user) }
  let(:mutual_follow_user){ create(:user) }
  let(:followable_type)   { "User" }

  context "when ids are present" do
    before do
      sign_in current_user

      # current_user follows…
      current_user.follow(followed_user)
      current_user.follow(mutual_follow_user)

      # …and is followed by…
      follow_back_user.follow(current_user)
      mutual_follow_user.follow(current_user)
    end

    it "returns correct following values" do
      ids = [
        followed_user.id,
        not_followed_user.id,
        current_user.id,
        follow_back_user.id,
        mutual_follow_user.id
      ]

      get bulk_show_follows_path,
          params: { ids: ids, followable_type: followable_type }

      body = response.parsed_body
      expect(body[current_user.id.to_s]).to      eq("self")
      expect(body[followed_user.id.to_s]).to    eq("true")
      expect(body[not_followed_user.id.to_s]).to eq("false")
      expect(body[follow_back_user.id.to_s]).to eq("follow-back")
      expect(body[mutual_follow_user.id.to_s]).to eq("mutual")
    end
  end

  it "without ids raises a missing param error" do
    sign_in current_user
    expect { get bulk_show_follows_path, params: { followable_type: followable_type } }
      .to raise_error(ActionController::ParameterMissing)
  end

  it "rejects unless logged-in" do
    sign_out current_user
    get bulk_show_follows_path, params: { ids: [], followable_type: followable_type }

    expect(response.body).to eq("not-logged-in")
  end
end
