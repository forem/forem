require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName

RSpec.describe "Api::V1::Docs::Followers", appmap: false do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let(:api_secret) { create(:api_secret) }
  let(:user) { api_secret.user }
  let(:follower1) { create(:user) }
  let(:follower2) { create(:user) }

  before do
    follower1.follow(user)
    follower2.follow(user)
    user.reload
  end

  describe "GET /followers/users" do
    path "/api/followers/users" do
      get "Followers" do
        tags "followers"
        description(<<-DESCRIBE.strip)
        This endpoint allows the client to retrieve a list of the followers they have.
        "Followers" are users that are following other users on the website.
        It supports pagination, each page will contain 80 followers by default.
        DESCRIBE
        operationId "getFollowers"
        produces "application/json"

        parameter "$ref": "#/components/parameters/pageParam"
        parameter "$ref": "#/components/parameters/perPageParam30to1000"
        parameter name: :sort, in: :query, required: false,
                  description: "Default is 'created_at'. Specifies the sort order for the created_at param of the follow
                                relationship. To sort by newest followers first (descending order) specify
                                ?sort=-created_at.",
                  schema: { type: :string },
                  example: "created_at"

        response "200", "A List of followers" do
          let(:"api-key") { api_secret.secret }
          schema  type: :array,
                  items: {
                    description: "A follower",
                    type: "object",
                    properties: {
                      type_of: { description: "user_follower by default", type: :string },
                      id: { type: :integer, format: :int32 },
                      user_id: { description: "The follower's user id", type: :integer, format: :int32 },
                      name: { description: "The follower's name", type: :string },
                      path: { description: "A path to the follower's profile", type: :string },
                      profile_image: { description: "Profile image (640x640)", type: :string }
                    }
                  }

          add_examples
          run_test!
        end

        response "401", "unauthorized" do
          let(:"api-key") { nil }
          add_examples

          run_test!
        end
      end
    end
  end
end

# rubocop:enable RSpec/EmptyExampleGroup
# rubocop:enable RSpec/VariableName
