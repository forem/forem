require "rails_helper"

RSpec.describe "ApplicationController", type: :request do
  let!(:user) { create(:user) }
  let!(:controller) { ApplicationController.new }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "#feature_flag_enabled?" do
    it "calls FeatureFlag.enabled_for_user with current_user" do
      allow(FeatureFlag).to receive(:enabled_for_user?)
      controller.feature_flag_enabled?("flag_name")
      expect(FeatureFlag).to have_received(:enabled_for_user?)
        .with("flag_name", user)
    end
  end
end
