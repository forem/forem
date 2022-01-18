require "rails_helper"

RSpec.describe "Feedback report", type: :system do
  let(:user) { create(:user) }
  let(:message) { Faker::Lorem.paragraph }
  let(:url) { Faker::Lorem.sentence }

  context "when user creates too many report abuse feedback messages" do
    let(:rate_limit_checker) { RateLimitChecker.new(user) }

    before do
      # avoid hitting new user rate limit check
      allow(user).to receive(:created_at).and_return(1.week.ago)
      allow(RateLimitChecker).to receive(:new).and_return(rate_limit_checker)
      allow(rate_limit_checker).to receive(:limit_by_action)
        .with(:feedback_message_creation)
        .and_return(true)
    end

    it "displays a rate limit warning", :flaky, js: true do
      visit report_abuse_path
      choose("Other")
      fill_in "feedback_message_message", with: message
      fill_in "feedback_message_reported_url", with: url
      click_button "Send Feedback"
      expect(page).to have_current_path("/feedback_messages")
      expect(page).to have_text("Rate limit reached")
    end
  end
end
