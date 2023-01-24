require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName

RSpec.describe "Api::V1::Docs::ProfileImages", appmap: false do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let(:api_secret) { create(:api_secret) }
  let(:user) { api_secret.user }

  describe "GET /profile_images/{username}" do
    path "/api/profile_images/{username}" do
      get "A Users or organizations profile image" do
        tags "profile images"
        description(<<-DESCRIBE.strip)
        This endpoint allows the client to retrieve a user or organization profile image information by its
        corresponding username.
        DESCRIBE
        operationId "getProfileImage"
        produces "application/json"
        parameter name: :username, in: :path, required: true,
                  description: "The parameter is the username of the user or the username of the organization.",
                  schema: { type: :string },
                  example: "janedoe"

        response "200", "An object containing profile image details" do
          let(:"api-key") { api_secret.secret }
          let(:username) { user.username }
          schema  type: :object,
                  items: { "$ref": "#/components/schemas/ProfileImage" }
          add_examples

          run_test!
        end

        response "404", "Resource Not Found" do
          let(:"api-key") { api_secret.secret }
          let(:username) { "something_random16" }
          add_examples

          run_test!
        end
      end
    end
  end
end
# rubocop:enable RSpec/VariableName
# rubocop:enable RSpec/EmptyExampleGroup
