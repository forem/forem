require "rails_helper"

RSpec.describe "Creator config edit", type: :system, js: true do
  let(:admin) { create(:user, :super_admin) }

  context "when a creator browses /admin/customization/config" do
    before do
      sign_in admin
      allow(ForemInstance).to receive(:private?).and_return(false)
      allow(FeatureFlag).to receive(:enabled?).with(:forem_passport).and_return(true)
    end

    it "presents all available OAuth providers" do
      visit admin_config_path

      within("div[data-target='#authenticationBodyContainer']") do
        click_on("Show info", match: :first)
      end

      Authentication::Providers.available.each do |provider|
        element = find(".config-authentication__item--label", text: /#{provider}/i)
        expect(element).not_to be_nil
      end
    end
  end
end
