require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName
# rubocop:disable Layout/LineLength

RSpec.describe "Api::V1::Docs::Follows" do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let(:user) { create(:user) }
  let(:api_secret) { create(:api_secret, user: user) }

  describe "POST /follows" do
    path "/api/follows" do
      post "Follow users or organizations" do
        tags "follows"
        description "Follow users or organizations in bulk on behalf of the authenticated user.

### Bulk Update Behavior:
- Accepts arrays of `user_ids` and `organization_ids` in the request body.
- Performs follow actions for all provided identifiers.
- Highly efficient for onboarding flows or importing social connections."
        consumes "application/json"
        produces "application/json"
        parameter name: :follow_params, in: :body,
                  description: "Map containing lists of user and organization IDs to follow.",
                  schema: {
                    type: :object,
                    properties: {
                      user_ids: {
                        type: :array,
                        items: { type: :integer }
                      },
                      organization_ids: {
                        type: :array,
                        items: { type: :integer }
                      }
                    }
                  }

        response "200", "successful" do
          let(:"api-key") { api_secret.secret }
          let(:another_user) { create(:user) }
          let(:follow_params) { { user_ids: [another_user.id], organization_ids: [] } }
          schema type: :object, properties: {
            outcome: { type: :string }
          }
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
