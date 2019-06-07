require "rails_helper"

RSpec.describe "/internal/reports", type: :request do
  let(:feedback_message)  { create(:feedback_message, :abuse_report) }
  let(:feedback_message2) { create(:feedback_message, :abuse_report) }
  let(:feedback_message3) { create(:feedback_message, :abuse_report) }
  let(:user)              { create(:user) }
  let(:admin)             { create(:user, :super_admin) }

  describe "POST /save_status" do
    context "when a valid request is made" do
      before do
        sign_in admin
        valid_save_status_params = { status: "Resolved" }
        valid_save_status_params[:id] = feedback_message.id
        post "/internal/reports/save_status", params:
          valid_save_status_params
      end

      it "returns a JSON with an outcome key and Success value" do
        expect(JSON.parse(response.body)).to eq("outcome" => "Success")
      end

      it "updates the status of the feedback message" do
        expect(FeedbackMessage.last.status).to eq("Resolved")
      end
    end
  end

  describe "POST /send_email" do
    context "when a valid request is made" do
      valid_send_email_params = {
        "feedback_message_id" => 1,
        "email_subject" => "Thank you for your report",
        "email_body" => "Thanks for your report and being an awesome member!",
        "email_type" => "reporter"
      }

      email_message_attributes = {
        "feedback_message_id" => 1,
        "subject" => "Thank you for your report",
        "utm_campaign" => "reporter"
      }

      before do
        feedback_message
        sign_in admin
        valid_send_email_params["email_to"] = user.email
        post "/internal/reports/send_email", params:
          valid_send_email_params
      end

      it "returns a JSON with an outcome key and Success value" do
        expect(JSON.parse(response.body)).to eq("outcome" => "Success")
      end

      it "creates a new email message with the same params" do
        email_message_attributes["to"] = user.email
        expect(EmailMessage.last.attributes).to include(email_message_attributes)
      end
    end
  end

  describe "POST /internal/reports/create_note" do
    context "when a valid request is made" do
      note_params = {
        "content" => "test note",
        "reason" => "abuse-reports",
        "noteable_type" => "FeedbackMessage"
      }

      json_response = {
        outcome: "Success",
        content: "test note"
      }

      before do
        allow(SlackBot).to receive(:ping).and_return(true)
        feedback_message
        sign_in admin
        note_params["noteable_id"] = feedback_message.id
        note_params["author_id"] = admin.id
        post "/internal/reports/create_note", params: note_params
      end

      it "renders the proper JSON response" do
        json_response["author_name"] = admin.name
        expect(response.body).to eq(json_response.to_json)
      end

      it "creates a note with the correct params" do
        expect(Note.last.attributes).to include(note_params)
      end
    end
  end
end
