require "rails_helper"

RSpec.describe "Creator config edit", type: :system, js: true do
  let(:admin) { create(:user, :super_admin) }

  # Apple auth is in Beta so we need to enable the Feature Flag to test it
  before { Flipper.enable(:apple_auth) }

  context "when a creator browses /admin/customization/config" do
    before do
      sign_in admin
      allow(Settings::Authentication).to receive(:invite_only_mode).and_return(false)
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
