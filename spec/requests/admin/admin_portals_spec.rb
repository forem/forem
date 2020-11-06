require "rails_helper"

RSpec.describe "/admin", type: :request do
  let(:super_admin) { create(:user, :super_admin) }

  before { sign_in super_admin }

  describe "profile admin feature flag" do
    it "shows the option when the feature flag is enabled" do
      allow(Flipper).to receive(:enabled?).with(:profile_admin).and_return(true)

      get admin_path

      expect(response.body).to include("Config: Profile Setup")
    end

    it "does not show the option when the feature flag is disabled" do
      allow(Flipper).to receive(:enabled?).with(:profile_admin).and_return(false)

      get admin_path

      expect(response.body).not_to include("Config: Profile Setup")
    end
  end
end
