require "rails_helper"

RSpec.describe "User uses response templates settings" do
  let(:user) { create(:user) }
  let(:response_template) { create(:response_template, user: user) }

  context "when user is signed in" do
    before do
      sign_in user
      response_template
    end

    context "when user has a response template already" do
      it "can go to the edit page of the response template" do
        visit "/settings/response-templates"
        click_on "Edit"

        expect(page).to have_current_path "/settings/response-templates/#{response_template.id}", ignore_query: true
      end

      it "shows the proper message when deleting a response template", :aggregate_failures do
        visit "/settings/extensions"
        expect(page).to have_text(response_template.title)
        expect(page).to have_css(".flex-1", text: response_template.title)
        expect(page).to have_css("form[action='#{response_template_path(response_template.id)}'][onsubmit*='confirm(']")

        click_on "Remove"

        expect(page).to have_text "was deleted."
      end
    end
  end
end
