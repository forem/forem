require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName
# rubocop:disable Layout/LineLength

RSpec.describe "Api::V1::Docs::FeedbackMessages" do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let(:admin) { create(:user, :super_admin) }
  let(:admin_api_secret) { create(:api_secret, user: admin) }
  let!(:feedback_msg) { create(:feedback_message) }

  describe "PATCH /api/feedback_messages/{id}" do
    path "/api/feedback_messages/{id}" do
      patch "Update a feedback message's status (Admin)" do
        tags "feedback_messages", "admin"
        description "Update the status of a user feedback message or report.

### Feedback Messages Overview:
- Feedback messages are submitted by users via support forms or content abuse reporting modals.
- Requires Administrator privileges.
- Used to track moderation/resolution workflows (e.g. marking a spam report as `Resolved`, `Spam`, or `Ignored`)."
        consumes "application/json"
        produces "application/json"
        parameter name: :id, in: :path, required: true,
                  description: "Unique feedback message ID.",
                  schema: { type: :integer }
        parameter name: :feedback_params, in: :body,
                  description: "Feedback parameters containing the status updates.",
                  schema: {
                    type: :object,
                    properties: {
                      feedback_message: {
                        type: :object,
                        properties: {
                          status: { type: :string }
                        },
                        required: [:status]
                      }
                    }
                  }

        response "200", "successful" do
          let(:"api-key") { admin_api_secret.secret }
          let(:id) { feedback_msg.id }
          let(:feedback_params) { { feedback_message: { status: "Resolved" } } }
          add_examples
          run_test!
        end
      end
    end
  end
end

# rubocop:enable RSpec/VariableName
# rubocop:enable RSpec/EmptyExampleGroup
# rubocop:enable Layout/LineLength
