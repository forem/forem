require "rails_helper"

RSpec.describe "Creating Comment", type: :system, js: true do
  include_context "with runkit_tag"

  let(:user) { create(:user) }
  let(:raw_comment) { Faker::Lorem.paragraph }
  let(:runkit_comment) { compose_runkit_comment "comment 1" }
  let(:runkit_comment2) { compose_runkit_comment "comment 2" }
  let(:twitter_comment) { "comment {% twitter_timeline https://twitter.com/NYTNow/timelines/576828964162965504 %}" }

  # the article should be created before signing in
  let!(:article) { create(:article, user_id: user.id, show_comments: true) }

  before do
    sign_in user
  end

  it "User fills out comment box normally" do
    visit article.path.to_s
    wait_for_javascript

    fill_in "text-area", with: raw_comment
    click_button("Submit")
    expect(page).to have_text(raw_comment)
  end

  context "when user makes too many comments" do
    let(:rate_limit_checker) { RateLimitChecker.new(user) }

    before do
      allow(RateLimitChecker).to receive(:new).and_return(rate_limit_checker)
      allow(rate_limit_checker).to receive(:limit_by_action)
        .with(:comment_creation)
        .and_return(true)
    end

    it "displays a rate limit modal" do
      visit article.path.to_s
      wait_for_javascript

      fill_in "text-area", with: raw_comment
      click_button("Submit")
      expect(page).to have_text("Wait a moment...")
    end

    it "closes modal with close button" do
      visit article.path.to_s
      wait_for_javascript

      fill_in "text-area", with: raw_comment
      click_button("Submit")
      click_button("Got it")
      expect(page).not_to have_text("Wait a moment...")
    end

    it "closes model with 'x' image button" do
      visit article.path.to_s
      wait_for_javascript

      fill_in "text-area", with: raw_comment
      click_button("Submit")
      find(".crayons-modal__box__header").click_button
      expect(page).not_to have_text("Wait a moment...")
    end
  end

  context "when there is an error posting a comment" do
    let(:unconfigured_twitter_comment) { "{% twitter 733111952256335874 %}" }

    before do
      stub_request(:post, "https://api.twitter.com/oauth2/token")
        .to_return(status: 400, body: '{"errors":[{"code":215,"message":"Bad Authentication data."}]}', headers: {})
    end

    it "displays a error modal" do
      visit article.path.to_s
      wait_for_javascript

      fill_in "text-area", with: unconfigured_twitter_comment
      click_button("Submit")
      expect(page).to have_text("Error posting comment")
    end
  end

  context "with Runkit tags" do
    before do
      visit article.path.to_s

      wait_for_javascript
    end

    it "Users fills out comment box with a Runkit tag" do
      fill_in "text-area", with: runkit_comment
      click_button("Submit")

      expect_runkit_tag_to_be_active
    end

    it "Users fills out comment box 2 Runkit tags" do
      fill_in "text-area", with: runkit_comment
      click_button("Submit")

      expect_runkit_tag_to_be_active

      fill_in "text-area", with: runkit_comment2
      click_button("Submit")

      expect_runkit_tag_to_be_active(count: 2)
    end

    it "User fill out comment box with a Runkit tag, then clicks preview" do
      fill_in "text-area", with: runkit_comment
      click_button("Preview")

      expect_runkit_tag_to_be_active
    end
  end

  context "with TwitterTimeline tag" do
    before do
      visit article.path.to_s

      wait_for_javascript
    end

    it "User fill out comment box with a TwitterTimeline tag, then clicks preview" do
      fill_in "text-area", with: twitter_comment
      click_button("Preview")

      expect(page).to have_css(".ltag-twitter-timeline-body iframe", count: 1)
    end
  end

  it "User fill out comment box then click previews and submit" do
    visit article.path.to_s
    wait_for_javascript

    fill_in "text-area", with: raw_comment
    click_button("Preview")
    expect(page).to have_text(raw_comment)
    expect(page).to have_text("Continue editing")
    click_button("Continue editing")
    expect(page).to have_text("Preview")
    click_button("Submit")
    expect(page).to have_text(raw_comment)
  end

  it "User replies to a comment" do
    create(:comment, commentable: article, user_id: user.id)
    visit article.path.to_s

    wait_for_javascript

    find(".toggle-reply-form").click
    find(:xpath, "//textarea[contains(@id, \"textarea-for\")]").set(raw_comment)
    click_button("Submit")
    expect(page).to have_text(raw_comment)
  end

  # This is basically a black box test for
  # ./app/javascripts/packs/validateFileInputs.js
  # which is logic to validate file size and format when uploading via a form.
  it "User attaches a valid image" do
    visit article.path.to_s

    attach_file(
      "image-upload-main",
      Rails.root.join("app/assets/images/apple-icon.png"),
      visible: :hidden,
    )

    expect(page).to have_no_css("div.file-upload-error")
  end

  it "User attaches a large image" do
    visit article.path.to_s

    reduce_max_file_size = 'document.getElementById("image-upload-main").setAttribute("data-max-file-size-mb", "0")'
    page.execute_script(reduce_max_file_size)
    expect(page).to have_selector('input[data-max-file-size-mb="0"]', visible: :hidden)

    attach_file(
      "image-upload-main",
      Rails.root.join("app/assets/images/onboarding-background.png"),
      visible: :hidden,
    )

    expect(page).to have_css(
      "div.file-upload-error",
      text: "File size too large (0.07 MB). The limit is 0 MB.",
      visible: :hidden,
    )
  end

  it "User attaches an invalid file type" do
    visit article.path.to_s

    allow_vids = 'document.getElementById("image-upload-main").setAttribute("data-permitted-file-types", "[\"video\"]")'
    page.execute_script(allow_vids)
    expect(page).to have_selector('input[data-permitted-file-types="[\"video\"]"]', visible: :hidden)

    attach_file(
      "image-upload-main",
      Rails.root.join("app/assets/images/apple-icon.png"),
      visible: :hidden,
    )

    expect(page).to have_css(
      "div.file-upload-error",
      text: "Invalid file format (image). Only video files are permitted.",
      visible: :hidden,
    )
  end

  it "User attaches a file with too long of a name" do
    visit article.path.to_s

    limit_length = 'document.getElementById("image-upload-main").setAttribute("data-max-file-name-length", "5")'
    page.execute_script(limit_length)
    expect(page).to have_selector('input[data-max-file-name-length="5"]', visible: :hidden)

    attach_file(
      "image-upload-main",
      Rails.root.join("app/assets/images/apple-icon.png"),
      visible: :hidden,
    )

    expect(page).to have_css(
      "div.file-upload-error",
      text: "File name is too long. It can't be longer than 5 characters.",
      visible: :hidden,
    )
  end
end
