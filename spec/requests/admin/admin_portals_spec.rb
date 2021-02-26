require "rails_helper"

RSpec.describe "/admin", type: :request do
  let(:super_admin) { create(:user, :super_admin) }

  before do
    sign_in super_admin
    allow(FeatureFlag).to receive(:enabled?).and_call_original
  end

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
    before do
      ForemInstance.instance_variable_set(:@deployed_at, nil)
    end

    after do
      ForemInstance.instance_variable_set(:@deployed_at, nil)
    end

    it "shows the correct value if the Last deployed time is available" do
      stub_const("ENV", ENV.to_h.merge("HEROKU_RELEASE_CREATED_AT" => "Some date"))

      get admin_path

      expect(response.body).to include(ENV["HEROKU_RELEASE_CREATED_AT"])
    end
  end

  describe "data update scripts admin feature flag" do
    it "shows the option when the feature flag is enabled" do
      allow(FeatureFlag).to receive(:enabled?).with(:data_update_scripts).and_return(true)

      get admin_path

      expect(response.body).to include("Tech Resources")
      expect(response.body).to include("Data Update Scripts")
    end

    it "does not show the option when the feature flag is disabled" do
      allow(FeatureFlag).to receive(:enabled?).with(:data_update_scripts).and_return(false)

      get admin_path

      expect(response.body).not_to include("Tech Resources")
      expect(response.body).not_to include("Data Update Scripts")
    end
  end
end
