require "rails_helper"

RSpec.describe "admin/display_ads/new" do
  let(:admin) { build(:user, :super_admin) }

  before do
    assign(:display_ad, build(:display_ad))
  end

  context "when signed-in" do
    before do
      sign_in admin
    end

    it "works as expected" do
      render
      expect(rendered).to have_css("#placement_area")
    end
  end
end
