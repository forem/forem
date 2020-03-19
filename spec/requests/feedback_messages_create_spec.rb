require "rails_helper"

RSpec.describe "feedback_messages", type: :request do
  describe "POST /feedback_messages" do
    # rubocop:disable RSpec/AnyInstance
    def verify_captcha_and_slack_ping
      allow_any_instance_of(FeedbackMessagesController).
        to receive(:recaptcha_verified?).and_return(true)
      allow(SlackClient).to receive(:ping).and_return(true)
    end
    # rubocop:enable RSpec/AnyInstance

    valid_abuse_report_params = {
      feedback_message: {
        feedback_type: "abuse-reports",
        category: "rude or vulgar",
        reported_url: "https://dev.to",
        message: "this was vulgar"
      }
    }

    context "with valid params" do
      before do
        verify_captcha_and_slack_ping
      end

      it "creates a feedback message" do
        expect do
          post feedback_messages_path, params: valid_abuse_report_params
        end.to change(FeedbackMessage, :count).by(1)

        feedback_message = FeedbackMessage.last
        expect(feedback_message.message).to eq(
          valid_abuse_report_params[:feedback_message][:message],
        )
      end

      it "queues a slack message to be sent" do
        sidekiq_assert_enqueued_with(job: SlackBotPingWorker) do
          post feedback_messages_path, params: valid_abuse_report_params
        end
      end
    end

    context "with invalid recaptcha" do
      it "rerenders page" do
        post "/feedback_messages", params: valid_abuse_report_params
        expect(response.body).to include("Make sure the forms are filled")
      end

      it "queues a slack message to be sent" do
        sidekiq_assert_no_enqueued_jobs(only: SlackBotPingWorker) do
          post feedback_messages_path, params: valid_abuse_report_params
        end
      end
    end

    context "when a user submits a report" do
      let(:user) { create(:user) }

      before do
        verify_captcha_and_slack_ping
        sign_in(user)
      end

      it "creates a feedback message reported by the user" do
        post feedback_messages_path, params: valid_abuse_report_params

        expect(FeedbackMessage.exists?(reporter_id: user.id)).to be(true)
      end

      it "queues a slack message to be sent" do
        sidekiq_assert_enqueued_jobs(1, only: SlackBotPingWorker) do
          post feedback_messages_path, params: valid_abuse_report_params
        end
      end
    end

    context "when an anonymous user submits a report" do
      before do
        verify_captcha_and_slack_ping
      end

      it "does not add any user as the reporter" do
        post "/feedback_messages", params: valid_abuse_report_params

        expect(FeedbackMessage.last.reporter).to be(nil)
      end

      it "queues a slack message to be sent" do
        sidekiq_assert_enqueued_jobs(1, only: SlackBotPingWorker) do
          post feedback_messages_path, params: valid_abuse_report_params
        end
      end

      it "redirects to the index page" do
        post "/feedback_messages", params: valid_abuse_report_params

        expect(response).to redirect_to(feedback_messages_path)
      end

      it "redirects and continues to the index page with the correct message" do
        post "/feedback_messages", params: valid_abuse_report_params

        follow_redirect!

        expect(response.body).to include("Thank you for your report.")
      end
    end
  end
end
