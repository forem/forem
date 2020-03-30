require "rails_helper"

RSpec.describe "User uses response templates settings", type: :system do
  let!(:user) { create(:user) }
  let(:response_template) { create(:response_template, user: user) }

  context "when user is signed in" do
    before do
      sign_in user
      response_template
    end

    context "when user has a response template already" do
      it "can go to the edit page of the response template" do
        visit "/settings/response-templates"
        click_link "EDIT"
        expect(page).to have_current_path "/settings/response-templates/#{response_template.id}", ignore_query: true
      end

      it "can delete a response template properly", js: true do
        visit "/settings/response-templates"
        click_button "DELETE"
        page.driver.browser.switch_to.alert.accept
        expect(ResponseTemplate.count).to eq 0
      end
    end
  end
end
