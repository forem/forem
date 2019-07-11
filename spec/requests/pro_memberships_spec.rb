require "rails_helper"

RSpec.describe "Pro Memberships", type: :request do
  describe "POST /pro" do
    let(:user) { create(:user) }

    context "when the user is not logged in" do
      it "redirects to the sign up page" do
        post "/pro"
        expect(response).to redirect_to(sign_up_path)
      end
    end

    context "when the user is logged in and already has a pro memberships" do
      before do
        sign_in user
      end

      it "does not authorize creation if it has an active membership" do
        create(:pro_membership, user: user)
        expect do
          post "/pro"
        end.to raise_error(Pundit::NotAuthorizedError)
      end

      it "does not authorize creation if it has an expired membership" do
        create(:pro_membership, :expired, user: user)
        expect do
          post "/pro"
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when the user is logged in without a pro membership and enough credits" do
      before do
        sign_in user
        create_list(:credit, ProMembership::MONTHLY_COST, user: user)
      end

      it "creates an active pro membership" do
        expect do
          post "/pro"
        end.to change(ProMembership, :count).by(1)
        expect(user.reload.pro_membership.active?).to be(true)
      end

      it "buys the pro membership with the correct amount of credits" do
        expect do
          post "/pro"
        end.to change(user.credits.spent, :count).by(ProMembership::MONTHLY_COST)
      end

      it "redirects to the show page with a notice" do
        post "/pro"
        expect(response).to redirect_to(pro_membership_path)
        expect(flash[:notice]).to eq("You are now a Pro!")
      end
    end

    context "when the user is logged in without a pro membership and not enough credits" do
      before do
        sign_in user
      end

      it "does not create an active pro membership" do
        expect do
          post "/pro"
        end.to change(ProMembership, :count).by(0)
      end

      it "does not subtract credits" do
        expect do
          post "/pro"
        end.to change(user.credits.spent, :count).by(0)
      end

      it "redirects to the show page with an error message" do
        post "/pro"
        expect(response).to redirect_to(pro_membership_path)
        expect(flash[:error]).to eq("You don't have enough credits!")
      end
    end
  end
end
# rubocop:enable RSpec/NestedGroups
