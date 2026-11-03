require "rails_helper"

RSpec.describe "Admin manages reports" do
  let(:admin) { create(:user, :super_admin, :without_profile, profile_image: nil) }
  let(:user) { create(:user, :without_profile, profile_image: nil) }
  let(:user2) { create(:user, :without_profile, profile_image: nil) }
  let!(:feedback_message) do
    create(:feedback_message, :abuse_report, reporter_id: user.id, reported_url: "zzzzzzz999")
  end
  let!(:feedback_message3) do
    create(:feedback_message, :abuse_report, reporter_id: user2.id, reported_url: "https://obscure-example-1984.net")
  end

  def clear_search_boxes
    fill_in "q_reporter_username_cont", with: ""
    fill_in "q_reported_url_cont", with: ""
  end

  before do
    create(:feedback_message, :abuse_report, reporter_id: user.id, status: "Invalid")
    sign_in admin
    visit admin_feedback_messages_path
  end

  it "loads the view, sorts results, and searches reports", :aggregate_failures do
    expect(page).to have_content("Feedback Messages")

    2.times { click_on("Reported URL") }
    expect(first(".edit_feedback_message")[:id]).to eq("edit_feedback_message_#{feedback_message.id}")

    clear_search_boxes
    fill_in "q_reporter_username_cont", with: user.username.to_s
    click_on "Search"

    expect(page).to have_css("#edit_feedback_message_#{feedback_message.id}")
    expect(page).to have_no_css("#edit_feedback_message_#{feedback_message3.id}")

    clear_search_boxes
    fill_in "q_reported_url_cont", with: feedback_message3.reported_url.to_s
    click_on "Search"
    expect(page).to have_css("#edit_feedback_message_#{feedback_message3.id}")
  end
end
