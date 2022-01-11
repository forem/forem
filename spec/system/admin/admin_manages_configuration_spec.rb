require "rails_helper"

RSpec.describe "Admin manages configuration", type: :system do
  let(:admin) { create(:user, :super_admin) }

  before do
    sign_in admin
    visit admin_config_path
  end

  Settings::Mandatory::MAPPINGS.each do |option, _setting_model|
    it "marks #{option} as required" do
      selector = "label[for='settings_general_#{option}']"
      expect(first(selector).text).to include("Required")
    end
  end
end
