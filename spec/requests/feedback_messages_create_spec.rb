require "rails_helper"

RSpec.describe "feedback_messages", type: :request do
  describe "POST /feedback_messages" do
    # rubocop:disable RSpec/AnyInstance
    before do
      allow_any_instance_of(FeedbackMessagesController).
        to receive(:recaptcha_verified?).and_return(true)
      allow_any_instance_of(Slack::Notifier).to receive(:ping).and_return(true)
    end
    # rubocop:enable RSpec/AnyInstance

    valid_abuse_report_params = {
      feedback_message: {
        feedback_type: "abuse-reports",
        category: "rude or vulgar",
        reported_url: "https://dev.to",
        message: "this was vulgar",
      },
    }

    context "with valid params" do
      before do
        post "/feedback_messages", params: valid_abuse_report_params
      end

      it "creates feedback message with filled form" do
        expect(FeedbackMessage.last.message).to eq(
          valid_abuse_report_params[:feedback_message][:message],
        )
      end

      xit "redirects to the ticket page" do
        expect(response).to redirect_to(FeedbackMessage.last.path)
      end
    end

    context "when a logged in user submits report" do
      let(:user)         { create(:user) }
      let(:mail_message) { instance_double(Mail::Message, deliver: true) }

      before do
        allow(NotifyMailer).to receive(:new_report_email).and_return(mail_message)
        login_as(user)
        post "/feedback_messages", params: valid_abuse_report_params
      end

      it "adds the logged in user as as the reporter" do
        expect(FeedbackMessage.find_by(reporter_id: user.id)).not_to eq(nil)
      end

      xit "sends an email to the reporter" do
        expect(NotifyMailer).to have_received(:new_report_email)
      end
    end
  end
end
