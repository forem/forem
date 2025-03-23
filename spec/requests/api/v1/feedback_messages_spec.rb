# spec/requests/api/v1/feedback_messages_spec.rb
require "rails_helper"

RSpec.describe "Api::V1::FeedbackMessages" do
  let!(:v1_headers) do
    {
      "Content-Type" => "application/json",
      "Accept" => "application/vnd.forem.api-v1+json"
    }
  end

  let!(:feedback_message) { create(:feedback_message) }

  shared_context "when user is authorized" do
    let(:api_secret) { create(:api_secret) }
    let(:user) { api_secret.user }
    let(:auth_header) { v1_headers.merge({ "api-key" => api_secret.secret }) }

    before { user.add_role(:admin) }
  end

  describe "PATCH/PUT /api/v1/feedback_messages/:id" do
    let(:params) do
      {
        feedback_message: {
          status: "Resolved"
        }
      }
    end

    context "when unauthenticated" do
      it "returns unauthorized" do
        patch api_feedback_message_path(feedback_message),
              params: params.to_json,
              headers: v1_headers

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated but not authorized" do
      let(:non_admin_secret) { create(:api_secret) }
      let(:non_auth_header)  { v1_headers.merge("api-key" => non_admin_secret.secret) }

      it "returns unauthorized" do
        patch api_feedback_message_path(feedback_message),
              params: params.to_json,
              headers: non_auth_header

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authorized" do
      include_context "when user is authorized"

      context "when the feedback message does not exist" do
        it "returns not found" do
          patch api_feedback_message_path(1234),
                params: params.to_json,
                headers: auth_header

          expect(response).to have_http_status(:not_found)
        end
      end

      context "when the feedback message exists" do
        it "updates the feedback message" do
          patch api_feedback_message_path(feedback_message),
                params: params.to_json,
                headers: auth_header

          expect(response).to have_http_status(:ok)
          expect(feedback_message.reload.status).to eq("Resolved")
        end

        # If you handle invalid params or other scenarios, you can add more specs here.
        # e.g., it "returns unprocessable_entity when given invalid params"
      end
    end
  end
end
