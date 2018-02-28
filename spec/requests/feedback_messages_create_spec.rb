require "rails_helper"

RSpec.describe "feedback_messages", type: :request do
  describe "POST /feedback_messages" do
    before do
      allow_any_instance_of(FeedbackMessagesController).to receive(:recaptcha_verified?).and_return(true)
      allow_any_instance_of(Slack::Notifier).to receive(:ping).and_return(true)
    end
    it "creates feedback message with filled form" do
      new_body = "NEW BODY #{rand(100)}"
      post "/feedback_messages", params: {
        feedback_message: { feedback_type: "abuse-reports",
                            category_selection: "other",
                            message: new_body },
      }
      expect(FeedbackMessage.last.message).to eq(new_body)
    end
  end
end
