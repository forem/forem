require "rails_helper"

RSpec.describe "Feedback report" do
  let(:user) { create(:user) }
  let(:message) { Faker::Lorem.paragraph }
  let(:url) { Faker::Lorem.sentence }

  context "when user create a report abuse feedback message" do
    before do
      sign_in user
    end

    it "feedback message should increase by one" do
      expect do
        post "/feedback_messages", params: {
          feedback_message: {
            message: message,
            feedback_type: "abuse-reports",
            category: "rude or vulgar",
            reported_url: url
          }
        }, as: :json
      end.to change(FeedbackMessage, :count).by(1)
    end
  end

  context "when user creates too many report abuse feedback messages" do
    let(:rate_limit_checker) { RateLimitChecker.new }

    before do
      allow(RateLimitChecker).to receive(:new).and_return(rate_limit_checker)
      allow(rate_limit_checker).to receive(:limit_by_action)
        .with(:feedback_message_creation)
        .and_return(true)
    end

    it "displays a rate limit warning", :aggregate_failures do
      visit report_abuse_path
      choose("Other")
      fill_in "feedback_message_message", with: message
      fill_in "feedback_message_reported_url", with: url
      click_on "Send Feedback"
      expect(page).to have_current_path("/feedback_messages")
      expect(page).to have_text("Rate limit reached")
    end
  end
end
