require "rails_helper"

RSpec.describe "Creating Comment", type: :feature, js: true do
  let(:user) { create(:user) }
  let(:raw_comment) { Faker::Lorem.paragraph }
  let(:article) do
    create(:article, user_id: user.id, show_comments: true)
  end

  before do
    sign_in user
  end

  it "User fills out comment box normally" do
    visit article.path.to_s
    fill_in "text-area", with: raw_comment
    click_button("SUBMIT")
    expect(page).to have_text(raw_comment)
  end

  # rubocop:disable RSpec/ExampleLength
  it "User fill out commen box then click previews and submit" do
    visit user.path
    visit article.path.to_s
    fill_in "text-area", with: raw_comment
    find(".checkbox").click
    click_button("PREVIEW")

    expect(page).to have_text(raw_comment)
    expect(page).to have_text("MARKDOWN")
    click_button("MARKDOWN")
    # expect(page).to have_text(raw_comment)
    expect(page).to have_text("PREVIEW")
    click_button("SUBMIT")
    expect(page).to have_text(raw_comment)
  end

  it "User replies to a comment" do
    create(:comment, commentable_id: article.id, user_id: user.id)
    visit article.path.to_s
    find(".toggle-reply-form").click
    find(:xpath, "//div[@class='actions']/form[@class='new_comment']/textarea").set(raw_comment)
    find(:xpath, "//div[contains(@class, 'reply-actions')]/input[@name='commit']").click
    expect(page).to have_text(raw_comment)
  end
  # rubocop:enable RSpec/ExampleLength
end
