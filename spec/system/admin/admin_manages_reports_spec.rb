require "rails_helper"

RSpec.describe "Admin manages reports" do
  let(:admin) { create(:user, :super_admin) }

  def clear_search_boxes
    fill_in "q_reporter_username_cont", with: ""
    fill_in "q_reported_url_cont", with: ""
  end

  before do
    sign_in admin
    visit admin_feedback_messages_path
  end

  it "loads the view" do
    expect(page).to have_content("Feedback Messages")
  end

  context "when searching for reports" do
    let(:user) { create(:user) }
    let(:user2) { create(:user) }
    let!(:feedback_message) do
      create(:feedback_message, :abuse_report, reporter_id: user.id, reported_url: "zzzzzzz999")
    end
    let!(:feedback_message3) do
      create(:feedback_message, :abuse_report, reporter_id: user2.id, reported_url: "https://obscure-example-1984.net")
    end

    before do
      create(:feedback_message, :abuse_report, reporter_id: user.id, status: "Invalid")
      clear_search_boxes
    end

    it "searches reports" do
      fill_in "q_reporter_username_cont", with: user.username.to_s
      click_button "Search"

      expect(page).to have_css("#edit_feedback_message_#{feedback_message.id}")
      expect(page).not_to have_css("#edit_feedback_message_#{feedback_message3.id}")

      clear_search_boxes

      fill_in "q_reported_url_cont", with: feedback_message3.reported_url.to_s
      click_button "Search"
      expect(page).to have_css("#edit_feedback_message_#{feedback_message3.id}")
    end

    it "sorts results" do
      2.times { click_link("Reported URL") }
      expect(first(".edit_feedback_message")[:id]).to eq("edit_feedback_message_#{feedback_message.id}")
    end
  end
end
