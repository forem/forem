require "rails_helper"

RSpec.describe "Admin manages reports", type: :system do
  let(:admin) { create(:user, :super_admin) }

  def clear_search_boxes
    fill_in "q_reporter_username_cont", with: ""
    fill_in "q_reported_url_cont", with: ""
    select "", from: "q_status_eq"
  end

  before do
    sign_in admin
    visit internal_feedback_messages_path
  end

  it "renders the page", js: true, percy: true do
    Percy.snapshot(page, name: "Admin: /internal/feedback_messages")
  end

  it "loads the view" do
    expect(page).to have_content("Feedback Messages")
    expect(page).to have_content("Suspicious Activity")
  end

  context "when searching for reports" do
    let(:user) { create(:user) }
    let(:user2) { create(:user) }
    let!(:feedback_message) { create(:feedback_message, :abuse_report, reporter_id: user.id, reported_url: "zzzzzzz999") }
    let!(:feedback_message2) { create(:feedback_message, :abuse_report, reporter_id: user.id, status: "Invalid") }
    let!(:feedback_message3) { create(:feedback_message, :abuse_report, reporter_id: user2.id, reported_url: "https://obscure-example-1984.net") }

    before do
      clear_search_boxes
    end

    it "renders the page when searching reports", js: true, percy: true do
      fill_in "q_reporter_username_cont", with: user.username.to_s
      click_on "Search"

      Percy.snapshot(page, name: "Admin: /internal/feedback_messages search")
    end

    it "searches reports" do
      fill_in "q_reporter_username_cont", with: user.username.to_s
      click_on "Search"

      expect(page).to have_css("#edit_feedback_message_#{feedback_message.id}")
      expect(page).not_to have_css("#edit_feedback_message_#{feedback_message3.id}")

      clear_search_boxes

      fill_in "q_reported_url_cont", with: feedback_message3.reported_url.to_s
      click_on "Search"
      expect(page).to have_css("#edit_feedback_message_#{feedback_message3.id}")
    end

    it "renders the page when filtering", js: true, percy: true do
      select "Invalid", from: "q[status_eq]"
      click_on "Search"

      Percy.snapshot(page, name: "Admin: /internal/feedback_messages filter")
    end

    it "filters by reports by status" do
      select "Invalid", from: "q[status_eq]"
      click_on "Search"

      expect(page).not_to have_css("#edit_feedback_message_#{feedback_message.id}")
      expect(page).not_to have_css("#edit_feedback_message_#{feedback_message3.id}")
      expect(page).to have_css("#edit_feedback_message_#{feedback_message2.id}")
    end

    it "sorts results" do
      2.times { click_on("Reported URL") }
      expect(first(".edit_feedback_message")[:id]).to eq("edit_feedback_message_#{feedback_message.id}")
    end
  end
end
