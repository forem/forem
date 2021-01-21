require "rails_helper"

# Regression test for https://github.com/forem/forem/issues/12131
RSpec.describe "", type: :system do
  let(:correct_liquid_tag) do
    "{% codepen https://codepen.io/user/pen/abcdefg default-tab=result %}"
  end
  let(:incorrect_liquid_tag) do
    '{% codepen https://codepen.io/user/pen/abcdefg default-tab="result" %}'
  end

  it "let's the user fix a broken draft without publishing", js: true, aggregate_failures: true do
    # Create a new blog post and add content that validates correctly
    sign_in create(:user, editor_version: "v2")
    visit new_path
    fill_in "article-form-title", with: "Regression spec"
    fill_in "article_body_markdown", with: correct_liquid_tag

    # Save the draft
    click_button "Save draft"
    expect(page).to have_content("Unpublished Post")

    # Edit the blog post with content that doesn't pass validations
    click_link("Click to edit")
    fill_in "article_body_markdown", with: incorrect_liquid_tag

    # Try to save the draft, there should still be both "Publish" and "Save Draft" buttons
    click_button "Save draft"
    expect(page).to have_content("Whoops, something went wrong")
    expect(page).to have_selector(:link_or_button, "Publish")
    expect(page).to have_selector(:link_or_button, "Save ")

    # Fix the error
    fill_in "article_body_markdown", with: correct_liquid_tag
    click_button "Save draft"
    expect(page).to have_content("Unpublished Post")
  end
end
