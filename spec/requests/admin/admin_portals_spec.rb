require "rails_helper"

RSpec.describe "/admin", type: :request do
  let(:super_admin) { create(:user, :super_admin) }

  before { sign_in super_admin }

  describe "profile admin feature flag" do
    it "shows the option when the feature flag is enabled" do
      allow(FeatureFlag).to receive(:enabled?).with(:profile_admin).and_return(true)

      get admin_path

      expect(response.body).to include("Config: Profile Setup")
    end

    it "does not show the option when the feature flag is disabled" do
      allow(FeatureFlag).to receive(:enabled?).with(:profile_admin).and_return(false)

      get admin_path

      expect(response.body).not_to include("Config: Profile Setup")
    end
  end

  describe "Last deployed and Lastest Commit ID card" do
    it "shows 'Not Available' if the Last deployed time is missing" do
      stub_const("ENV", ENV.to_h.merge("HEROKU_RELEASE_CREATED_AT" => ""))

      get admin_path

      expect(response.body).to include("Not Available")
    end

    it "shows the correct value if the Last deployed time is available" do
      stub_const("ENV", ENV.to_h.merge("HEROKU_RELEASE_CREATED_AT" => "Some date"))

      get admin_path

      expect(response.body).to include(ENV["HEROKU_RELEASE_CREATED_AT"])
    end
  end
end
