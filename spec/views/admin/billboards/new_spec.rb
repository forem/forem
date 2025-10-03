require "rails_helper"

RSpec.describe "admin/billboards/new" do
  let(:admin) { build(:user, :super_admin) }

  before do
    assign(:billboard, build(:billboard))
  end

  context "when signed-in" do
    before do
      sign_in admin
    end

    it "works as expected" do
      render
      expect(rendered).to have_css("#placement_area")
    end

    it "includes the expires_at field" do
      render
      expect(rendered).to have_css("input[name='expires_at']")
      expect(rendered).to have_text("Billboard will automatically be marked as not approved after this time")
    end
  end
end
