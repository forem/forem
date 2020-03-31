require "rails_helper"

RSpec.describe "Creating Comment", type: :system, js: true do
  let(:user) { create(:user) }
  let(:raw_comment) { Faker::Lorem.paragraph }
  # the article should be created before signing in
  let!(:article) { create(:article, user_id: user.id, show_comments: true) }

  before do
    sign_in user
  end

  it "User fills out comment box normally" do
    visit article.path.to_s

    wait_for_javascript

    fill_in "text-area", with: raw_comment
    click_button("SUBMIT")
    expect(page).to have_text(raw_comment)
  end

  it "User fill out comment box then click previews and submit" do
    visit article.path.to_s

    wait_for_javascript

    fill_in "text-area", with: raw_comment
    click_button("PREVIEW")
    expect(page).to have_text(raw_comment)
    expect(page).to have_text("MARKDOWN")
    click_button("MARKDOWN")
    expect(page).to have_text("PREVIEW")
    click_button("SUBMIT")
    expect(page).to have_text(raw_comment)
  end

  it "User replies to a comment" do
    create(:comment, commentable: article, user_id: user.id)
    visit article.path.to_s

    wait_for_javascript

    find(".toggle-reply-form").click
    find(:xpath, "//div[@class='actions']/form[@class='new_comment']/textarea").set(raw_comment)
    find(:xpath, "//div[contains(@class, 'reply-actions')]/input[@name='commit']").click
    expect(page).to have_text(raw_comment)
  end

  # This is basically a black box test for
  # ./app/javascripts/packs/validateFileInputs.js
  # which is logic to validate file size and format when uploading via a form.
  it "User attaches a valid image" do
    visit article.path.to_s

    attach_file(
      "image-upload-main",
      Rails.root.join("app/assets/images/sloan.png"),
      visible: false,
    )

    expect(page).to have_no_css("div.file-upload-error")
  end

  it "User attaches a large image" do
    visit article.path.to_s

    reduce_max_file_size = 'document.querySelector("#image-upload-main").setAttribute("data-max-file-size-mb", "0")'
    page.execute_script(reduce_max_file_size)
    expect(page).to have_selector('input[data-max-file-size-mb="0"]', visible: false)

    attach_file(
      "image-upload-main",
      Rails.root.join("app/assets/images/sloan.png"),
      visible: false,
    )

    expect(page).to have_css("div.file-upload-error")
    expect(page).to have_css(
      "div.file-upload-error",
      text: "File size too large (0.29 MB). The limit is 0 MB.",
    )
  end

  it "User attaches an invalid file type" do
    visit article.path.to_s

    allow_only_videos = 'document.querySelector("#image-upload-main").setAttribute("data-permitted-file-types", "[\"video\"]")'
    page.execute_script(allow_only_videos)
    expect(page).to have_selector('input[data-permitted-file-types="[\"video\"]"]', visible: false)

    attach_file(
      "image-upload-main",
      Rails.root.join("app/assets/images/sloan.png"),
      visible: false,
    )

    expect(page).to have_css("div.file-upload-error")
    expect(page).to have_css(
      "div.file-upload-error",
      text: "Invalid file format (image). Only video files are permitted.",
    )
  end

  it "User attaches a file with too long of a name" do
    visit article.path.to_s

    limit_file_name_length = 'document.querySelector("#image-upload-main").setAttribute("data-max-file-name-length", "5")'
    page.execute_script(limit_file_name_length)
    expect(page).to have_selector('input[data-max-file-name-length="5"]', visible: false)

    attach_file(
      "image-upload-main",
      Rails.root.join("app/assets/images/sloan.png"),
      visible: false,
    )

    expect(page).to have_css("div.file-upload-error")
    expect(page).to have_css(
      "div.file-upload-error",
      text: "File name is too long. It can't be longer than 5 characters.",
    )
  end
end
