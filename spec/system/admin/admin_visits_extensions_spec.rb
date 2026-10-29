require "rails_helper"

RSpec.describe "Admin visits extentions page" do
  let(:super_admin) { create(:user, :super_admin, :without_profile, profile_image: nil) }

  before do
    sign_in super_admin
    visit admin_extensions_path
  end

  it "nests the content under Developer Tools and highlights the menu item in the sidebar", :aggregate_failures do
    expect(find("h1.crayons-title").text).to eq("Developer Tools")

    within('nav[aria-label="Admin"]') do
      expect(find("[aria-current='page']").text).to eq("Developer Tools")
    end
  end
end
