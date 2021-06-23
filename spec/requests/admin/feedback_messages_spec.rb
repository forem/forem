require "rails_helper"

RSpec.describe "/admin/moderation/reports", type: :request do
  let(:feedback_message)  { create(:feedback_message, :abuse_report) }
  let(:user)              { create(:user) }
  let(:trusted_user)      { create(:user, :trusted) }
  let(:admin)             { create(:user, :super_admin) }

  describe "GET /admin/moderation/reports" do
    let(:single_resource_admin) { create(:user, :single_resource_admin, resource: FeedbackMessage) }

    context "when the user is a single resource admin" do
      it "renders with status 200" do
        sign_in single_resource_admin
        get admin_reports_path
        expect(response.status).to eq 200
      end
    end

    context "when there is a vomit reaction on a user" do
      it "renders with status 200" do
        trusted_user
        create(:reaction, category: "vomit", reactable: user, user: trusted_user)
        sign_in admin
        get admin_reports_path
        expect(response.status).to eq 200
      end
    end
  end

  describe "POST /admin/moderation/reports/save_status" do
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
        post save_status_admin_reports_path, params: save_status_params

        expect(response.parsed_body).to eq("outcome" => "Success")
      end

      it "updates the status of the feedback message" do
        post save_status_admin_reports_path, params: save_status_params

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
          to: send_email_params[:email_to]
        }.stringify_keys
      end

      before do
        sign_in admin
      end

      it "returns a JSON with an outcome key and Success value" do
        post send_email_admin_reports_path, params: send_email_params

        expect(response.parsed_body).to eq("outcome" => "Success")
      end

      it "creates a new email message with the same params" do
        post send_email_admin_reports_path, params: send_email_params

        expect(EmailMessage.last.attributes).to include(email_message_attributes)
      end
    end
  end

  describe "POST /admin/moderation/reports/create_note" do
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
        post create_note_admin_reports_path, params: note_params

        expected_response = {
          outcome: "Success",
          content: "test note",
          author_name: admin.name
        }.stringify_keys
        expect(response.parsed_body).to eq(expected_response)
      end

      it "creates a note with the correct params" do
        post create_note_admin_reports_path, params: note_params

        expect(Note.last.attributes).to include(note_params)
      end

      it "queues a slack message to be sent" do
        sidekiq_assert_enqueued_with(job: Slack::Messengers::Worker) do
          post create_note_admin_reports_path, params: note_params
        end
      end
    end
  end
end
