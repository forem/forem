require "rails_helper"

RSpec.describe "Api::V0::Analytics", type: :request do
  let(:user)              { create(:user) }
  let(:api_token)         { create(:api_secret, user: user) }
  let(:org)               { create(:organization) }
  let(:pro_user)          { create(:user, :pro) }
  let(:pro_api_token)     { create(:api_secret, user: pro_user) }
  let(:pro_org_member)    { create(:user, :pro, :org_member) }
  let(:org_member_token)  { create(:api_secret, user: pro_org_member) }

  describe "GET /api/analytics/totals" do
    include_examples "GET /api/analytics/:endpoint authorization examples", "totals"
  end

  describe "GET /api/analytics/historical" do
    include_examples "GET /api/analytics/:endpoint authorization examples", "historical", "&start=2019-03-29"

    context "when the start parameter is not included" do
      it "raises an ArgumentError" do
        expect { get "/api/analytics/historical" }.to raise_error ArgumentError
      end
    end
  end

  describe "GET /api/analytics/past_day" do
    include_examples "GET /api/analytics/:endpoint authorization examples", "past_day"
  end
end
