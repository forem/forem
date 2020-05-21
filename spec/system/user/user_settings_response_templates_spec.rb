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
      it "renders the page", js: true, percy: true do
        visit "/settings/response-templates"

        Percy.snapshot(page, name: "Settings: /response-templates renders")

        click_link "Edit"

        Percy.snapshot(page, name: "Settings: /response-templates can edit")
      end

      it "can go to the edit page of the response template", js: true do
        visit "/settings/response-templates"
        click_link "Edit"

        expect(page).to have_current_path "/settings/response-templates/#{response_template.id}", ignore_query: true
      end

      it "renders the page when deleting a response template", js: true, percy: true do
        visit "/settings/response-templates"
        accept_confirm { click_button "Remove" }

        Percy.snapshot(page, name: "Settings: /response-templates can delete")
      end

      it "shows the proper message when deleting a reponse template", js: true do
        visit "/settings/response-templates"
        accept_confirm { click_button "Remove" }

        expect(page).to have_text "was deleted."
      end
    end
  end
end
