require "rails_helper"

RSpec.describe "Feedback report by chat channel messages", type: :system do
  let(:user) { create(:user) }

  context "when user create a report abuse feedback message" do
    before do
      sign_in user
    end

    it "feedback messahe should increase by one", js: true do
      expect do
        post "/feedback_messages", params: {
          feedback_message: {
            message: "Test Message",
            feedback_type: "connect",
            category: "rude or vulgar",
            offender_id: user.id
          }
        }, as: :json
      end.to change(FeedbackMessage, :count).by(1)
    end
  end
end
