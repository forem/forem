require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName

RSpec.describe "Api::V1::Docs::FollowedTags" do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let(:api_secret) { create(:api_secret) }
  let(:user) { api_secret.user }
  let(:tag1) { create(:tag) }
  let(:tag2) { create(:tag) }

  before do
    user.add_role(:admin)
    user.follow(tag1)
    user.follow(tag2)
  end

  describe "GET /follows/tags" do
    path "/api/follows/tags" do
      get "Followed Tags" do
        security []
        tags "followed_tags"
        description(<<-DESCRIBE.strip)
        This endpoint allows the client to retrieve a list of the tags they follow.
        DESCRIBE
        operationId "getFollowedTags"
        produces "application/json"

        response "200", "A List of followed tags" do
          let(:"api-key") { api_secret.secret }
          schema  type: :array,
                  items: { "$ref": "#/components/schemas/FollowedTags" }
          add_examples

          run_test!
        end

        response "401", "unauthorized" do
          let(:"api-key") { "invalid" }
          add_examples

          run_test!
        end
      end
    end
  end
end

# rubocop:enable RSpec/EmptyExampleGroup
# rubocop:enable RSpec/VariableName
