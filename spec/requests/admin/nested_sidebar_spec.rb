require "rails_helper"

# @ridhwana: rename to sidebar_spec once we can delete the old spec
RSpec.describe "admin sidebar", type: :request do
  let(:super_admin) { create(:user, :super_admin) }

  before do
    sign_in super_admin
    allow(FeatureFlag).to receive(:enabled?).and_call_original
  end

  describe "admin_restructure feature flag" do
    it "shows the correct options in the sidebar when the feature flag is enabled" do
      allow(FeatureFlag).to receive(:enabled?).with(:admin_restructure).and_return(true)

      get admin_articles_path

      expect(response.body).to include("Content Manager")
    end

    it "does not show the option in the sidebar when the feature flag is disabled" do
      allow(FeatureFlag).to receive(:enabled?).with(:admin_restructure).and_return(false)

      get admin_articles_path

      expect(response.body).not_to include("Content Manager")
    end
  end

  describe "sidebar menu options" do
    it "shows parent level and nested child items" do
      allow(FeatureFlag).to receive(:enabled?).with(:admin_restructure).and_return(true)

      get admin_articles_path

      expect(response.body).to include("Advanced")
      expect(response.body).to include("Developer Tools")
    end
  end

  describe "tabbed menu options" do
    # NOTE: [@ridhwana] to enable this test again once the
    # the feature flag is removed
    xit "shows nested grandchildren items where applicable" do
      allow(FeatureFlag).to receive(:enabled?).with(:admin_restructure).and_return(true)

      get admin_badges_path

      expect(response.body).to include("Library")
      expect(response.body).to include("Achievements")
    end
  end

  describe "profile admin feature flag" do
    before do
      allow(FeatureFlag).to receive(:enabled?).with(:admin_restructure).and_return(true)
    end

    it "does not show the option in the sidebar when the feature flag is disabled" do
      allow(FeatureFlag).to receive(:enabled?).with(:profile_admin).and_return(false)

      get admin_articles_path

      expect(response.body).not_to include("Profile Fields")
    end

    it "shows the option in the sidebar when the feature flag is enabled" do
      allow(FeatureFlag).to receive(:enabled?).with(:profile_admin).and_return(true)

      get admin_articles_path

      expect(response.body).to include("Profile Fields")
    end
  end

  describe "data update script admin feature flag" do
    before do
      allow(FeatureFlag).to receive(:enabled?).with(:admin_restructure).and_return(true)
    end

    it "does not show the option in the tabbed header when the feature flag is disabled" do
      allow(FeatureFlag).to receive(:enabled?).with(:data_update_scripts).and_return(false)

      get admin_tools_path

      expect(response.body).not_to include("Data Update Scripts")
    end

    # NOTE: [@ridhwana] to enable this test again once the
    # the feature flag is removed
    xit "shows the option in the tabbed header when the feature flag is enabled" do
      allow(FeatureFlag).to receive(:enabled?).with(:data_update_scripts).and_return(true)

      get admin_tools_path

      expect(response.body).to include("Data Update Scripts")
    end
  end
end
