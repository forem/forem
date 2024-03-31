require "rails_helper"

RSpec.describe "Admin visits extentions page" do
  let(:super_admin) { create(:user, :super_admin) }

  before do
    sign_in super_admin
    visit admin_extensions_path
  end

  it "nests the content under Developer Tools" do
    expect(find("h1.crayons-title").text).to eq("Developer Tools")
  end

  it "highlights the Developer Tools menu item in the sidebar" do
    within('nav[aria-label="Admin"]') do
      expect(find("[aria-current='page']").text).to eq("Developer Tools")
    end
  end
end
