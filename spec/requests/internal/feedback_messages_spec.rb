require "rails_helper"

RSpec.describe "/internal/reports", type: :request do
  let(:feedback_message)  { create(:feedback_message, :abuse_report) }
  let(:user)              { create(:user) }
  let(:admin)             { create(:user, :super_admin) }

  describe "POST /save_status" do
    context "when a valid request is made" do
      let(:save_status_params) do
        {
          status: "Resolved",
          id: feedback_message.id
        }
      end

      before do
        sign_in admin
      end

      it "returns a JSON with an outcome key and Success value" do
        post save_status_internal_reports_path, params: save_status_params

        expect(response.parsed_body).to eq("outcome" => "Success")
      end

      it "updates the status of the feedback message" do
        post save_status_internal_reports_path, params: save_status_params

        expect(FeedbackMessage.last.status).to eq("Resolved")
      end
    end
  end

  describe "POST /send_email" do
    context "when a valid request is made" do
      let(:send_email_params) do
        {
          feedback_message_id: feedback_message.id,
          email_subject: "Thank you for your report",
          email_body: "Thanks for your report and being an awesome member!",
          email_type: "reporter",
          email_to: user.email
        }
      end

      let(:email_message_attributes) do
        {
          feedback_message_id: send_email_params[:feedback_message_id],
          subject: send_email_params[:email_subject],
          utm_campaign: send_email_params[:email_type],
          to: send_email_params[:email_to]
        }.stringify_keys
      end

      before do
        sign_in admin
      end

      it "returns a JSON with an outcome key and Success value" do
        post send_email_internal_reports_path, params: send_email_params

        expect(response.parsed_body).to eq("outcome" => "Success")
      end

      it "creates a new email message with the same params" do
        post send_email_internal_reports_path, params: send_email_params

        expect(EmailMessage.last.attributes).to include(email_message_attributes)
      end
    end
  end

  describe "POST /internal/reports/create_note" do
    context "when a valid request is made" do
      let(:note_params) do
        {
          author_id: admin.id,
          content: "test note",
          reason: "abuse-reports",
          noteable_id: feedback_message.id,
          noteable_type: "FeedbackMessage"
        }.stringify_keys
      end

      before do
        sign_in admin
      end

      it "renders the proper JSON response" do
        post create_note_internal_reports_path, params: note_params

        expected_response = {
          outcome: "Success",
          content: "test note",
          author_name: admin.name
        }.stringify_keys
        expect(response.parsed_body).to eq(expected_response)
      end

      it "creates a note with the correct params" do
        post create_note_internal_reports_path, params: note_params

        expect(Note.last.attributes).to include(note_params)
      end

      it "queues a slack message to be sent" do
        sidekiq_assert_enqueued_with(job: SlackBotPingWorker) do
          post create_note_internal_reports_path, params: note_params
        end
      end
    end
  end
end
