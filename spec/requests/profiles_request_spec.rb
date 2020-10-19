require "rails_helper"

RSpec.describe "Profiles", type: :request do
  let(:profile) { create(:profile) }

  describe "POST /profiles" do
    context "when signed out" do
      it "redirects to the login page" do
        patch profile_path(profile), params: {}
        expect(response).to redirect_to(sign_up_path)
      end
    end

    context "when signed in" do
      before { sign_in(profile.user) }

      it "updates the profile" do
        new_name = "New name, who dis?"
        expect do
          patch profile_path(profile), params: { profile: { name: new_name } }
        end.to change { profile.reload.name }.to(new_name)
      end
    end
  end
end
