require "rails_helper"

RSpec.describe "Api::V0::Admin::Configs", type: :request do
  let(:user) { create(:user, :super_admin) } # not used by every spec but lower times overall

  describe "GET /api/admin/configs/all" do
    context "super admin signed in" do
      before do
        sign_in user
      end

      it "returns json" do
        get "/api/admin/configs/all"

        expect(response.parsed_body).to eq "Array"
      end
    end
  end
end
