require "rails_helper"

RSpec.describe "User leaves an organization" do
  let(:org_user) { create(:user, :without_profile, :org_member, profile_image: nil) }

  before do
    sign_in org_user
    visit "/settings/organization"
  end

  it "shows the leave organization button and leaves organization with confirmation", :aggregate_failures do
    expect(page).to have_button(I18n.t("views.settings.org.leave.submit"))

    click_on(I18n.t("views.settings.org.leave.submit"))

    expect(page).to have_content(I18n.t("users_controller.left_org"))
  end
end
