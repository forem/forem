require "rails_helper"

RSpec.describe "User leaves an organization" do
  let!(:org_user) { create(:user, :org_member) }
  let(:organization) { org_user.organizations.first }

  before do
    sign_in org_user
    visit "/settings/organization"
  end

  context "when user visits organization settings" do
    it "shows the leave organization button" do
      expect(page).to have_button(I18n.t("views.settings.org.leave.submit"))
    end
  end

  context "when user leaves member organization" do
    it "leaves organization and shows confirmation" do
      click_button(I18n.t("views.settings.org.leave.submit"))

      expect(page).to have_content(I18n.t("users_controller.left_org"))
    end
  end
end
