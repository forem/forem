require "rails_helper"

RSpec.describe "Follows #show" do
  let(:current_user) { create(:user) }
  let(:user) { create(:user) }
  let(:tag) { create(:tag) }
  let(:organization) { create(:organization) }
  let(:podcast) { create(:podcast) }

  before { sign_in current_user }

  def get_following_status
    %w[User Organization Tag Podcast].map do |type|
      get "/follows/#{__send__(type.downcase).id}", params: { followable_type: type }
      response.body
    end
  end

  it "rejects unless logged-in" do
    sign_out(user)
    get "/follows/#{user.id}"
    expect(response.body).to eq("not-logged-in")
  end

  it "returns false when not following" do
    expect(get_following_status.uniq[0]).to eq("false")
  end

  it "returns true when is following" do
    %w[user organization tag].each { |followable| current_user.follow(__send__(followable)) }
    expect(get_following_status.uniq[0]).to eq("true")
  end

  it "return self if current_user try to follow themself" do
    get "/follows/#{current_user.id}", params: { followable_type: "User" }
    expect(response.body).to eq("self")
  end
end
