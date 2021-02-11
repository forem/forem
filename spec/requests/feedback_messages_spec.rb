require "rails_helper"

RSpec.describe "feedback_messages", type: :request do
  let(:user) { create(:user) }

  describe "POST /feedback_messages" do
    def mock_recaptcha_verification
      # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(FeedbackMessagesController).to(
        receive(:recaptcha_verified?).and_return(true),
      )
      # rubocop:enable RSpec/AnyInstance
    end

    def mock_recaptcha_config_enabled
      allow(SiteConfig).to receive(:recaptcha_secret_key).and_return("someSecretKey")
      allow(SiteConfig).to receive(:recaptcha_site_key).and_return("someSiteKey")
    end

    valid_abuse_report_params = {
      feedback_message: {
        feedback_type: "abuse-reports",
        category: "rude or vulgar",
        reported_url: "https://dev.to",
        message: "this was vulgar"
      }
    }

    headers = { "HTTP_FASTLY_CLIENT_IP" => "5.6.7.8" }

    context "with valid params and recaptcha passed" do
      before do
        mock_recaptcha_verification
      end

      it "creates a feedback message" do
        expect do
          post feedback_messages_path, params: valid_abuse_report_params, headers: headers
        end.to change(FeedbackMessage, :count).by(1)

        feedback_message = FeedbackMessage.last
        expect(feedback_message.message).to eq(
          valid_abuse_report_params[:feedback_message][:message],
        )
      end

      it "queues a slack message to be sent" do
        sidekiq_assert_enqueued_with(job: Slack::Messengers::Worker) do
          post feedback_messages_path, params: valid_abuse_report_params, headers: headers
        end
      end

      it "doesn't try to send an email" do
        expect do
          perform_enqueued_jobs do
            post feedback_messages_path, params: valid_abuse_report_params, headers: headers
          end
        end.not_to change { ActionMailer::Base.deliveries.count }
      end
    end

    context "when feedback is created by chat" do
      before do
        sign_in user
        post "/feedback_messages", params: {
          feedback_message: {
            message: "Test Message",
            feedback_type: "connect",
            category: "rude or vulgar",
            offender_id: user.id
          }
        }, as: :json
      end

      it "creates a feedback message" do
        expect(response.status).to eq(200)
        expect(response.parsed_body["success"]).to eq(true)
        expect(FeedbackMessage.where(offender_id: user.id).count).to eq(1)
      end
    end

    context "with valid params and recaptcha not configured" do
      before do
        allow(SiteConfig).to receive(:recaptcha_secret_key).and_return(nil)
        allow(SiteConfig).to receive(:recaptcha_site_key).and_return(nil)
      end

      it "does not show the recaptcha tag" do
        get "/report-abuse"
        expect(response.body).not_to include("recaptcha-tag-container")
      end

      it "creates a feedback message" do
        expect do
          post feedback_messages_path, params: valid_abuse_report_params, headers: headers
        end.to change(FeedbackMessage, :count).by(1)
      end
    end

    context "when rate limit is reached" do
      it "returns a 429" do
        user = create(:user)
        limiter = user.rate_limiter
        allow(RateLimitChecker).to receive(:new) { limiter }
        allow(limiter).to receive(:limit_by_action).and_return(true)

        post "/feedback_messages", params: valid_abuse_report_params, headers: headers
        expect(response.status).to eq(429)
      end
    end

    context "with valid params but recaptcha not passed" do
      before { mock_recaptcha_config_enabled }

      it "rerenders page" do
        post feedback_messages_path, params: valid_abuse_report_params, headers: headers
        expect(response.body).to include("Make sure the forms are filled")
      end

      it "doesn't queues a slack message" do
        sidekiq_assert_no_enqueued_jobs(only: Slack::Messengers::Worker) do
          post feedback_messages_path, params: valid_abuse_report_params, headers: headers
        end
      end
    end

    context "when a user qualifies to bypass the recaptcha submits a report" do
      let(:user) { create(:user, created_at: 3.months.ago) }

      before do
        mock_recaptcha_config_enabled
        sign_in user
      end

      it "creates a feedback message reported by the user without recaptcha" do
        post feedback_messages_path, params: valid_abuse_report_params, headers: headers

        expect(FeedbackMessage.exists?(reporter_id: user.id)).to be(true)
      end

      it "queues a slack message to be sent" do
        sidekiq_assert_enqueued_jobs(1, only: Slack::Messengers::Worker) do
          post feedback_messages_path, params: valid_abuse_report_params, headers: headers
        end
      end

      it "sends an email when no cache" do
        expect do
          perform_enqueued_jobs do
            post feedback_messages_path, params: valid_abuse_report_params, headers: headers
          end
        end.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      it "queues a correct email when no cache" do
        mailer_class = NotifyMailer
        mailer = double
        message_delivery = double
        allow(mailer_class).to receive(:with).and_return(mailer)
        allow(mailer).to receive(:feedback_response_email).and_return(message_delivery)
        allow(message_delivery).to receive(:deliver_later)

        post feedback_messages_path, params: valid_abuse_report_params, headers: headers

        expect(mailer_class).to have_received(:with).with(email_to: user.email)
        expect(mailer).to have_received(:feedback_response_email)
        expect(message_delivery).to have_received(:deliver_later)
      end

      it "doesn't queue an email when cache is set" do
        allow(Rails.cache).to receive(:read).and_return(Time.current)
        expect do
          perform_enqueued_jobs do
            post feedback_messages_path, params: valid_abuse_report_params, headers: headers
          end
        end.not_to change { ActionMailer::Base.deliveries.count }
      end
    end

    context "when a user doesn't qualify to bypass the recaptcha submits a report" do
      let(:user) do
        user = create(:user, created_at: 2.months.ago)
        create(:reaction,
               category: "vomit",
               reactable: user,
               user: create(:user, :trusted),
               status: "confirmed")
        user
      end

      before do
        mock_recaptcha_config_enabled
        sign_in user
      end

      it "fails to create a feedback message reported without recaptcha" do
        post feedback_messages_path, params: valid_abuse_report_params, headers: headers

        expect(FeedbackMessage.exists?(reporter_id: user.id)).to be(false)
      end

      it "doesn't queue a slack message to be sent" do
        sidekiq_assert_enqueued_jobs(0, only: Slack::Messengers::Worker) do
          post feedback_messages_path, params: valid_abuse_report_params, headers: headers
        end
      end
    end

    context "when a moderator submits a report" do
      let(:user) { create(:user, :tag_moderator) }

      before do
        mock_recaptcha_config_enabled
        sign_in user
      end

      it "creates a feedback message reported by the moderator without recaptcha" do
        post feedback_messages_path, params: valid_abuse_report_params, headers: headers

        expect(FeedbackMessage.exists?(reporter_id: user.id)).to be(true)
      end

      it "queues a slack message to be sent" do
        sidekiq_assert_enqueued_jobs(1, only: Slack::Messengers::Worker) do
          post feedback_messages_path, params: valid_abuse_report_params, headers: headers
        end
      end
    end

    context "when an anonymous user submits a report" do
      before do
        mock_recaptcha_config_enabled
        mock_recaptcha_verification
      end

      it "does not add any user as the reporter" do
        post "/feedback_messages", params: valid_abuse_report_params, headers: headers

        expect(FeedbackMessage.last.reporter).to be(nil)
      end

      it "queues a slack message to be sent" do
        sidekiq_assert_enqueued_jobs(1, only: Slack::Messengers::Worker) do
          post feedback_messages_path, params: valid_abuse_report_params, headers: headers
        end
      end

      it "redirects to the index page" do
        post "/feedback_messages", params: valid_abuse_report_params, headers: headers

        expect(response).to redirect_to(feedback_messages_path)
      end

      it "redirects and continues to the index page with the correct message" do
        post "/feedback_messages", params: valid_abuse_report_params, headers: headers

        follow_redirect!

        expect(response.body).to include("Thank you for your report.")
      end
    end
  end
end
