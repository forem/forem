require "rails_helper"

RSpec.describe "Creator config edit" do
  let(:admin) { create(:user, :super_admin) }

  context "when a creator browses /admin/customization/config" do
    before do
      sign_in admin
      allow(ForemInstance).to receive(:private?).and_return(false)
    end

    it "presents all available OAuth providers", :aggregate_failures do
      visit admin_config_path
      find("summary", text: "Authentication").click

      Authentication::Providers.available_providers.each do |provider|
        expect(page).to have_css(".config-authentication__item--label", text: provider.official_name)
      end
    end
  end
end
