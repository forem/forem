require "rails_helper"

RSpec.describe "Survey Resubmission", :js, type: :system do
  let(:user) { create(:user) }
  let(:survey) { create(:survey, allow_resubmission: true) }
  let(:poll1) { create(:poll, survey: survey, type_of: :single_choice) }
  let(:poll2) { create(:poll, survey: survey, type_of: :text_input) }
  let(:option1) { create(:poll_option, poll: poll1, markdown: "Option 1") }
  let(:option2) { create(:poll_option, poll: poll1, markdown: "Option 2") }

  before do
    option1
    option2
    sign_in user
  end

  # Helper method to create a test page with embedded survey
  def visit_survey_page(survey)
    # Create a simple test page that embeds the survey
    visit "/subforems/new"
    # The subforems page should have the survey embedded if @survey is set
    # We'll need to ensure the survey is available in the controller
  end

  it "allows users to resubmit surveys when allow_resubmission is true" do
    # First, complete the survey
    visit "/subforems/new"

    # Answer the first poll
    find("[data-option-id='#{option1.id}']").click
    click_button "Next →"

    # Answer the second poll
    fill_in "survey-text-input", with: "Initial response"
    click_button "Finish"

    # Verify survey is completed
    expect(page).to have_content("Survey completed")

    # Refresh the page to simulate returning later
    visit "/subforems/new"

    # Should be able to resubmit since allow_resubmission is true
    expect(page).to have_content("Option 1")
    expect(page).to have_content("Option 2")

    # Change the answers
    find("[data-option-id='#{option2.id}']").click
    click_button "Next →"

    fill_in "survey-text-input", with: "Updated response"
    click_button "Finish"

    # Verify survey is completed again
    expect(page).to have_content("Survey completed")
  end

  it "prevents resubmission when allow_resubmission is false" do
    survey.update!(allow_resubmission: false)

    # First, complete the survey
    visit "/subforems/new"

    # Answer the first poll
    find("[data-option-id='#{option1.id}']").click
    click_button "Next →"

    # Answer the second poll
    fill_in "survey-text-input", with: "Initial response"
    click_button "Finish"

    # Verify survey is completed
    expect(page).to have_content("Survey completed")

    # Refresh the page to simulate returning later
    visit "/subforems/new"

    # Should show completion message and not allow resubmission
    expect(page).to have_content("Survey completed")
    expect(page).to have_no_content("Option 1")
    expect(page).to have_no_content("Option 2")
  end
end
